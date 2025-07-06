-- Improve Customers Schema Structure
-- 1. Rename customers.customers to customers.companies
-- 2. Add company_type column with config reference
-- 3. Replace contact boolean flags with flexible JSONB contact_types
-- 4. Remove prospects table and migrate data

-- =============================================================================
-- 1. CREATE NEW CATALOG TYPES FOR COMPANIES AND CONTACTS
-- =============================================================================

-- Company types catalog
INSERT INTO config.catalog_types (name, code, description, is_active) VALUES
('Tipos de Empresa', 'company_types', 'Clasificacion de empresas en el sistema', true);

-- Contact types catalog  
INSERT INTO config.catalog_types (name, code, description, is_active) VALUES
('Tipos de Contacto', 'contact_types', 'Tipos de contactos de empresas', true);

-- =============================================================================
-- 2. CREATE CATALOG OPTIONS FOR COMPANY TYPES
-- =============================================================================

INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'company_types'), 'Cliente', 'customer', 'CUSTOMER', '#10B981', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'company_types'), 'Prospecto', 'prospect', 'PROSPECT', '#3B82F6', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'company_types'), 'Socio', 'partner', 'PARTNER', '#F59E0B', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'company_types'), 'Proveedor', 'vendor', 'VENDOR', '#8B5CF6', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'company_types'), 'Distribuidor', 'supplier', 'SUPPLIER', '#06B6D4', 5, true);

-- =============================================================================
-- 3. CREATE CATALOG OPTIONS FOR CONTACT TYPES
-- =============================================================================

INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'contact_types'), 'Contacto Principal', 'primary', 'PRIMARY', '#EF4444', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'contact_types'), 'Contacto de Facturacion', 'billing', 'BILLING', '#10B981', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'contact_types'), 'Contacto Tecnico', 'technical', 'TECHNICAL', '#3B82F6', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'contact_types'), 'Contacto de Ventas', 'sales', 'SALES', '#F59E0B', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'contact_types'), 'Contacto de Soporte', 'support', 'SUPPORT', '#8B5CF6', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'contact_types'), 'Contacto Legal', 'legal', 'LEGAL', '#6B7280', 6, true);

-- =============================================================================
-- 4. ADD COMPANY_TYPE COLUMN TO customers.customers
-- =============================================================================

ALTER TABLE customers.customers 
ADD COLUMN company_type VARCHAR(50) DEFAULT 'CUSTOMER' NOT NULL; -- References catalog_options

-- =============================================================================
-- 5. MIGRATE PROSPECTS DATA TO customers.customers
-- =============================================================================

-- Insert prospects as companies with type PROSPECT
INSERT INTO customers.customers (
    business_name, commercial_name, email, phone, website, 
    industry, company_size, status, company_type, notes,
    created_at, updated_at, created_by, updated_by
)
SELECT 
    p.company_name,
    p.contact_name,
    p.email,
    p.phone,
    p.website,
    p.industry,
    p.company_size,
    CASE 
        WHEN p.status IN ('NEW_LEAD', 'CONTACTED', 'QUALIFIED') THEN 'ACTIVE'
        WHEN p.status = 'CONVERTED' THEN 'ACTIVE'
        WHEN p.status = 'LOST' THEN 'INACTIVE'
        ELSE 'ACTIVE'
    END,
    'PROSPECT',
    p.notes,
    p.created_at,
    p.updated_at,
    p.created_by,
    p.updated_by
FROM customers.prospects p;

-- =============================================================================
-- 6. RENAME customers.customers TO customers.companies
-- =============================================================================

-- Simply rename the table instead of creating new one
ALTER TABLE customers.customers RENAME TO companies;

-- =============================================================================
-- 7. ADD contact_types JSONB COLUMN TO customers.contacts
-- =============================================================================

ALTER TABLE customers.contacts 
ADD COLUMN contact_types JSONB DEFAULT '[]' NOT NULL;

-- =============================================================================
-- 8. MIGRATE BOOLEAN CONTACT FLAGS TO JSONB ARRAY
-- =============================================================================

-- Build contact_types array based on existing boolean flags
UPDATE customers.contacts 
SET contact_types = (
    SELECT jsonb_agg(contact_type)
    FROM (
        SELECT 'primary' as contact_type WHERE is_primary = true
        UNION ALL
        SELECT 'billing' as contact_type WHERE is_billing_contact = true
        UNION ALL
        SELECT 'technical' as contact_type WHERE is_technical_contact = true
    ) contact_type_list
    WHERE contact_type IS NOT NULL
);

-- =============================================================================
-- 9. UPDATE customers.contacts TO REFERENCE companies
-- =============================================================================

-- Add temporary column for new company reference
ALTER TABLE customers.contacts 
ADD COLUMN company_id UUID;

-- Update company_id to reference the migrated customer data in companies table
UPDATE customers.contacts 
SET company_id = customer_id;

-- Make company_id NOT NULL after data migration
ALTER TABLE customers.contacts 
ALTER COLUMN company_id SET NOT NULL;

-- Add foreign key constraint
ALTER TABLE customers.contacts 
ADD CONSTRAINT contacts_company_id_fkey 
FOREIGN KEY (company_id) REFERENCES customers.companies(id) ON DELETE CASCADE;

-- =============================================================================
-- 10. UPDATE customers.renewal_alerts TO REFERENCE companies
-- =============================================================================

-- Add temporary column for new company reference
ALTER TABLE customers.renewal_alerts 
ADD COLUMN company_id UUID;

-- Update company_id to reference the migrated customer data in companies table
UPDATE customers.renewal_alerts 
SET company_id = customer_id;

-- Make company_id NOT NULL after data migration
ALTER TABLE customers.renewal_alerts 
ALTER COLUMN company_id SET NOT NULL;

-- Add foreign key constraint
ALTER TABLE customers.renewal_alerts 
ADD CONSTRAINT renewal_alerts_company_id_fkey 
FOREIGN KEY (company_id) REFERENCES customers.companies(id) ON DELETE CASCADE;

-- =============================================================================
-- 11. DROP OLD COLUMNS AND TABLES
-- =============================================================================

-- Remove boolean flags from contacts (replaced by JSONB array)
ALTER TABLE customers.contacts 
DROP COLUMN is_primary,
DROP COLUMN is_billing_contact,
DROP COLUMN is_technical_contact;

-- Remove old customer_id column from contacts (replaced by company_id)
ALTER TABLE customers.contacts 
DROP COLUMN customer_id;

-- Remove old customer_id column from renewal_alerts (replaced by company_id)
ALTER TABLE customers.renewal_alerts 
DROP COLUMN customer_id;

-- Drop prospects table (data migrated to companies)
DROP TABLE customers.prospects CASCADE;

-- customers.customers table already renamed to companies, no need to drop

-- =============================================================================
-- 12. CREATE INDEXES FOR NEW STRUCTURE
-- =============================================================================

-- Companies indexes (company_type is new)
CREATE INDEX idx_companies_company_type ON customers.companies(company_type);

-- Contacts indexes (company_id and contact_types are new)
CREATE INDEX idx_contacts_company_id ON customers.contacts(company_id);
CREATE INDEX idx_contacts_contact_types ON customers.contacts USING GIN(contact_types);

-- Renewal alerts indexes (company_id is new)
CREATE INDEX idx_renewal_alerts_company_id ON customers.renewal_alerts(company_id);

-- Note: Other indexes already exist from the renamed table

-- =============================================================================
-- 13. ADD COMMENTS FOR CLARITY
-- =============================================================================

COMMENT ON TABLE customers.companies IS 'All business entities: customers, prospects, partners, vendors, suppliers';
COMMENT ON COLUMN customers.companies.company_type IS 'Type of company: CUSTOMER, PROSPECT, PARTNER, VENDOR, SUPPLIER (references catalog_options)';
COMMENT ON COLUMN customers.contacts.contact_types IS 'Array of contact types: ["primary", "billing", "technical", "sales", "support", "legal"]';
COMMENT ON COLUMN customers.contacts.company_id IS 'References the company this contact belongs to (replaces customer_id)';

-- =============================================================================
-- 14. NOTE: FOREIGN KEY UPDATES NEEDED
-- =============================================================================

-- Note: This migration removes customers.customers and customers.prospects tables.
-- All other tables that reference these will need their foreign keys updated in subsequent migrations
-- or application logic updates to reference customers.companies instead.