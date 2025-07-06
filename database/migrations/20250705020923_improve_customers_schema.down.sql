-- Rollback Customers Schema Improvements
-- Restore original customers.customers and customers.prospects tables

-- =============================================================================
-- 1. RECREATE customers.customers TABLE
-- =============================================================================

-- Create customers table with original structure
CREATE TABLE customers.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_name VARCHAR(200) NOT NULL,
    commercial_name VARCHAR(200),
    tax_id VARCHAR(50),
    email VARCHAR(255),
    phone VARCHAR(20),
    website VARCHAR(255),
    address_line_1 VARCHAR(255),
    address_line_2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100),
    industry VARCHAR(100),
    company_size VARCHAR(50),
    status VARCHAR(50) DEFAULT 'ACTIVE' NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id),
    deleted_at TIMESTAMP,
    deleted_by UUID REFERENCES auth.users(id)
);

-- =============================================================================
-- 2. RECREATE customers.prospects TABLE
-- =============================================================================

CREATE TABLE customers.prospects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name VARCHAR(200) NOT NULL,
    contact_name VARCHAR(200),
    email VARCHAR(256),
    phone VARCHAR(20),
    website VARCHAR(255),
    industry VARCHAR(100),
    company_size VARCHAR(50),
    lead_source VARCHAR(50),
    status VARCHAR(50) NOT NULL,
    assigned_sales_rep_id UUID REFERENCES auth.users(id),
    estimated_value NUMERIC(12,2),
    estimated_close_date DATE,
    notes TEXT,
    priority VARCHAR(20) DEFAULT 'MEDIUM',
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP,
    last_contacted_at TIMESTAMP,
    next_follow_up_date DATE,
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    organization_id UUID REFERENCES auth.organizations(id),
    customer_id UUID REFERENCES customers.customers(id)
);

-- =============================================================================
-- 3. MIGRATE DATA BACK FROM companies TO customers AND prospects
-- =============================================================================

-- Migrate CUSTOMER type companies back to customers table
INSERT INTO customers.customers (
    id, business_name, commercial_name, tax_id, email, phone, website,
    address_line_1, address_line_2, city, state_province, postal_code, country,
    industry, company_size, status, is_active, notes,
    created_at, created_by, updated_at, updated_by, deleted_at, deleted_by
)
SELECT 
    id, business_name, commercial_name, tax_id, email, phone, website,
    address_line_1, address_line_2, city, state_province, postal_code, country,
    industry, company_size, status, is_active, notes,
    created_at, created_by, updated_at, updated_by, deleted_at, deleted_by
FROM customers.companies 
WHERE company_type = 'CUSTOMER';

-- Migrate PROSPECT type companies back to prospects table
INSERT INTO customers.prospects (
    company_name, contact_name, email, phone, website, industry, company_size,
    status, notes, created_at, updated_at, created_by, updated_by
)
SELECT 
    business_name,
    commercial_name,
    email,
    phone,
    website,
    industry,
    company_size,
    CASE 
        WHEN status = 'ACTIVE' THEN 'QUALIFIED'
        WHEN status = 'INACTIVE' THEN 'LOST'
        ELSE 'NEW_LEAD'
    END,
    notes,
    created_at,
    updated_at,
    created_by,
    updated_by
FROM customers.companies 
WHERE company_type = 'PROSPECT';

-- =============================================================================
-- 4. RESTORE customers.contacts ORIGINAL STRUCTURE
-- =============================================================================

-- Add back original customer_id column
ALTER TABLE customers.contacts 
ADD COLUMN customer_id UUID;

-- Restore customer_id references
UPDATE customers.contacts 
SET customer_id = company_id;

-- Add back boolean contact flag columns
ALTER TABLE customers.contacts 
ADD COLUMN is_primary BOOLEAN DEFAULT false NOT NULL,
ADD COLUMN is_billing_contact BOOLEAN DEFAULT false NOT NULL,
ADD COLUMN is_technical_contact BOOLEAN DEFAULT false NOT NULL;

-- Migrate contact_types JSONB back to boolean flags
UPDATE customers.contacts 
SET 
    is_primary = (contact_types @> '["primary"]'),
    is_billing_contact = (contact_types @> '["billing"]'),
    is_technical_contact = (contact_types @> '["technical"]');

-- Make customer_id NOT NULL and add foreign key
ALTER TABLE customers.contacts 
ALTER COLUMN customer_id SET NOT NULL,
ADD CONSTRAINT contacts_customer_id_fkey 
FOREIGN KEY (customer_id) REFERENCES customers.customers(id) ON DELETE CASCADE;

-- Remove new columns
ALTER TABLE customers.contacts 
DROP COLUMN contact_types,
DROP COLUMN company_id;

-- =============================================================================
-- 5. RESTORE customers.renewal_alerts ORIGINAL STRUCTURE
-- =============================================================================

-- Add back original customer_id column
ALTER TABLE customers.renewal_alerts 
ADD COLUMN customer_id UUID;

-- Restore customer_id references
UPDATE customers.renewal_alerts 
SET customer_id = company_id;

-- Make customer_id NOT NULL and add foreign key
ALTER TABLE customers.renewal_alerts 
ALTER COLUMN customer_id SET NOT NULL,
ADD CONSTRAINT renewal_alerts_customer_id_fkey 
FOREIGN KEY (customer_id) REFERENCES customers.customers(id) ON DELETE CASCADE;

-- Remove new company_id column
ALTER TABLE customers.renewal_alerts 
DROP COLUMN company_id;

-- =============================================================================
-- 6. DROP NEW TABLES AND CATALOG DATA
-- =============================================================================

-- Drop companies table
DROP TABLE customers.companies CASCADE;

-- Remove catalog options
DELETE FROM config.catalog_options 
WHERE catalog_type_id IN (
    SELECT id FROM config.catalog_types 
    WHERE code IN ('company_types', 'contact_types')
);

-- Remove catalog types
DELETE FROM config.catalog_types 
WHERE code IN ('company_types', 'contact_types');

-- =============================================================================
-- 7. RECREATE ORIGINAL INDEXES
-- =============================================================================

-- Customers indexes
CREATE INDEX idx_customers_active ON customers.customers(is_active);
CREATE INDEX idx_customers_business_name ON customers.customers(business_name);
CREATE INDEX idx_customers_deleted_at ON customers.customers(deleted_at);
CREATE INDEX idx_customers_status ON customers.customers(status);
CREATE INDEX idx_customers_tax_id ON customers.customers(tax_id);

-- Prospects indexes
CREATE INDEX idx_prospects_assigned_sales_rep ON customers.prospects(assigned_sales_rep_id);
CREATE INDEX idx_prospects_company_name ON customers.prospects(company_name);
CREATE INDEX idx_prospects_customer_id ON customers.prospects(customer_id);
CREATE INDEX idx_prospects_next_follow_up ON customers.prospects(next_follow_up_date);
CREATE INDEX idx_prospects_organization_id ON customers.prospects(organization_id);
CREATE INDEX idx_prospects_status ON customers.prospects(status);

-- Contacts indexes
CREATE INDEX idx_contacts_customer_id ON customers.contacts(customer_id);
CREATE INDEX idx_contacts_email ON customers.contacts(email);

-- Renewal alerts indexes
CREATE INDEX idx_renewal_alerts_alert_date ON customers.renewal_alerts(alert_date);
CREATE INDEX idx_renewal_alerts_assigned_to ON customers.renewal_alerts(assigned_to);
CREATE INDEX idx_renewal_alerts_customer_id ON customers.renewal_alerts(customer_id);
CREATE INDEX idx_renewal_alerts_status ON customers.renewal_alerts(status);

-- =============================================================================
-- 8. REMOVE COMMENTS
-- =============================================================================

COMMENT ON TABLE customers.customers IS NULL;
COMMENT ON TABLE customers.contacts IS NULL;