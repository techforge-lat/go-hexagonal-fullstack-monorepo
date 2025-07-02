-- Schema Redesign with CRM functionality
-- This migration organizes existing tables into logical schemas and adds CRM capabilities

-- =============================================================================
-- 1. CREATE SCHEMAS
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS customers;
CREATE SCHEMA IF NOT EXISTS products;
CREATE SCHEMA IF NOT EXISTS billing;
CREATE SCHEMA IF NOT EXISTS sales;
CREATE SCHEMA IF NOT EXISTS config;
CREATE SCHEMA IF NOT EXISTS support;

-- =============================================================================
-- 2. CONFIGURATION SYSTEM (config schema)
-- =============================================================================

-- Catalog Types: Define configuration categories
CREATE TABLE config.catalog_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

-- Catalog Options: Dynamic values for each type
CREATE TABLE config.catalog_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    catalog_type_id UUID NOT NULL REFERENCES config.catalog_types(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(100) NOT NULL,
    value VARCHAR(255),
    description TEXT,
    color_code VARCHAR(7), -- Hex colors like #3B82F6
    icon VARCHAR(50),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true NOT NULL,
    metadata JSONB DEFAULT '{}' NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP,
    CONSTRAINT catalog_options_type_code_uk UNIQUE (catalog_type_id, code)
);

-- =============================================================================
-- 3. MOVE EXISTING TABLES TO APPROPRIATE SCHEMAS
-- =============================================================================

-- Move authentication tables to auth schema
ALTER TABLE users SET SCHEMA auth;
ALTER TABLE resources SET SCHEMA auth;
ALTER TABLE resource_actions SET SCHEMA auth;
ALTER TABLE roles SET SCHEMA auth;
ALTER TABLE user_roles SET SCHEMA auth;
ALTER TABLE resource_role_permissions SET SCHEMA auth;

-- Move customer-related tables to customers schema  
ALTER TABLE customers SET SCHEMA customers;
ALTER TABLE contacts SET SCHEMA customers;
ALTER TABLE customer_users SET SCHEMA customers;

-- Move product-related tables to products schema
ALTER TABLE products SET SCHEMA products;
ALTER TABLE product_prices SET SCHEMA products;
ALTER TABLE contracts SET SCHEMA products;
ALTER TABLE contract_products SET SCHEMA products;

-- Move billing tables to billing schema
ALTER TABLE currencies SET SCHEMA billing;
ALTER TABLE payment_accounts SET SCHEMA billing;
ALTER TABLE payment_methods SET SCHEMA billing;
ALTER TABLE invoice_calculations SET SCHEMA billing;
ALTER TABLE invoice_calculation_items SET SCHEMA billing;
ALTER TABLE suppliers SET SCHEMA billing;
ALTER TABLE invoices SET SCHEMA billing;
ALTER TABLE invoice_items SET SCHEMA billing;
ALTER TABLE invoice_payments SET SCHEMA billing;

-- =============================================================================
-- 4. UPDATE FOREIGN KEY REFERENCES AFTER SCHEMA MOVES
-- =============================================================================

-- Update references to moved tables
ALTER TABLE auth.user_roles DROP CONSTRAINT user_roles_user_id_fk;
ALTER TABLE auth.user_roles ADD CONSTRAINT user_roles_user_id_fk 
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE auth.user_roles DROP CONSTRAINT user_roles_role_id_fk;
ALTER TABLE auth.user_roles ADD CONSTRAINT user_roles_role_id_fk 
    FOREIGN KEY (role_id) REFERENCES auth.roles(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE auth.resource_actions DROP CONSTRAINT resource_actions_resource_id_fk;
ALTER TABLE auth.resource_actions ADD CONSTRAINT resource_actions_resource_id_fk 
    FOREIGN KEY (resource_id) REFERENCES auth.resources(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE auth.resource_role_permissions DROP CONSTRAINT resource_role_permissions_resource_id_fk;
ALTER TABLE auth.resource_role_permissions ADD CONSTRAINT resource_role_permissions_resource_id_fk 
    FOREIGN KEY (resource_id) REFERENCES auth.resources(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE auth.resource_role_permissions DROP CONSTRAINT resource_role_permissions_role_id_fk;
ALTER TABLE auth.resource_role_permissions ADD CONSTRAINT resource_role_permissions_role_id_fk 
    FOREIGN KEY (role_id) REFERENCES auth.roles(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE auth.resource_role_permissions DROP CONSTRAINT resource_role_permissions_resource_action_id_fk;
ALTER TABLE auth.resource_role_permissions ADD CONSTRAINT resource_role_permissions_resource_action_id_fk 
    FOREIGN KEY (resource_action_id) REFERENCES auth.resource_actions(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE auth.roles DROP CONSTRAINT roles_customer_id_fk;
ALTER TABLE auth.roles ADD CONSTRAINT roles_customer_id_fk 
    FOREIGN KEY (customer_id) REFERENCES customers.customers(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE customers.customer_users DROP CONSTRAINT customer_users_customer_id_fk;
ALTER TABLE customers.customer_users ADD CONSTRAINT customer_users_customer_id_fk 
    FOREIGN KEY (customer_id) REFERENCES customers.customers(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE customers.customer_users DROP CONSTRAINT customer_users_user_id_fk;
ALTER TABLE customers.customer_users ADD CONSTRAINT customer_users_user_id_fk 
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE customers.contacts DROP CONSTRAINT contacts_company_id_fk;
ALTER TABLE customers.contacts ADD CONSTRAINT contacts_company_id_fk 
    FOREIGN KEY (company_id) REFERENCES customers.customers(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE products.product_prices DROP CONSTRAINT product_prices_product_id_fk;
ALTER TABLE products.product_prices ADD CONSTRAINT product_prices_product_id_fk 
    FOREIGN KEY (product_id) REFERENCES products.products(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE products.contracts DROP CONSTRAINT customer_product_contracts_customer_id_fk;
ALTER TABLE products.contracts ADD CONSTRAINT customer_product_contracts_customer_id_fk 
    FOREIGN KEY (owner_customer_id) REFERENCES customers.customers(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE products.contracts DROP CONSTRAINT customer_product_contracts_billing_customer_id_fk;
ALTER TABLE products.contracts ADD CONSTRAINT customer_product_contracts_billing_customer_id_fk 
    FOREIGN KEY (billing_customer_id) REFERENCES customers.customers(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE products.contract_products DROP CONSTRAINT contract_products_contract_id_fk;
ALTER TABLE products.contract_products ADD CONSTRAINT contract_products_contract_id_fk 
    FOREIGN KEY (contract_id) REFERENCES products.contracts(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE products.contract_products DROP CONSTRAINT contract_products_product_id_fk;
ALTER TABLE products.contract_products ADD CONSTRAINT contract_products_product_id_fk 
    FOREIGN KEY (product_id) REFERENCES products.products(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE products.contract_products DROP CONSTRAINT contract_products_product_price_id;
ALTER TABLE products.contract_products ADD CONSTRAINT contract_products_product_price_id 
    FOREIGN KEY (product_price_id) REFERENCES products.product_prices(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE billing.payment_accounts DROP CONSTRAINT payment_accounts_currency_id_fk;
ALTER TABLE billing.payment_accounts ADD CONSTRAINT payment_accounts_currency_id_fk 
    FOREIGN KEY (currency_id) REFERENCES billing.currencies(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE billing.invoice_calculations DROP CONSTRAINT invoice_calculations_billing_customer_id_fk;
ALTER TABLE billing.invoice_calculations ADD CONSTRAINT invoice_calculations_billing_customer_id_fk 
    FOREIGN KEY (billing_customer_id) REFERENCES customers.customers(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE billing.invoice_calculations DROP CONSTRAINT invoice_calculations_consumer_customer_id_fk;
ALTER TABLE billing.invoice_calculations ADD CONSTRAINT invoice_calculations_consumer_customer_id_fk 
    FOREIGN KEY (consumer_customer_id) REFERENCES customers.customers(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE billing.invoice_calculation_items DROP CONSTRAINT invoice_calculation_items_invoice_calculation_id_fk;
ALTER TABLE billing.invoice_calculation_items ADD CONSTRAINT invoice_calculation_items_invoice_calculation_id_fk 
    FOREIGN KEY (invoice_calculation_id) REFERENCES billing.invoice_calculations(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE billing.invoice_calculation_items DROP CONSTRAINT invoice_calculation_items_contract_product_id_fk;
ALTER TABLE billing.invoice_calculation_items ADD CONSTRAINT invoice_calculation_items_contract_product_id_fk 
    FOREIGN KEY (contract_product_id) REFERENCES products.contract_products(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE billing.invoices DROP CONSTRAINT invoices_billing_customer_id_fk;
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_billing_customer_id_fk 
    FOREIGN KEY (billing_customer_id) REFERENCES customers.customers(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE billing.invoices DROP CONSTRAINT invoices_accountable_customer_id_fk;
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_accountable_customer_id_fk 
    FOREIGN KEY (owner_customer_id) REFERENCES customers.customers(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE billing.invoices DROP CONSTRAINT invoices_invoice_calculation_id_fk;
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_invoice_calculation_id_fk 
    FOREIGN KEY (invoice_calculation_id) REFERENCES billing.invoice_calculations(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE billing.invoices DROP CONSTRAINT invoices_supplier_id_fk;
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_supplier_id_fk 
    FOREIGN KEY (supplier_id) REFERENCES billing.suppliers(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE billing.invoice_items DROP CONSTRAINT invoice_items_invoice_id_fk;
ALTER TABLE billing.invoice_items ADD CONSTRAINT invoice_items_invoice_id_fk 
    FOREIGN KEY (invoice_id) REFERENCES billing.invoices(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE billing.invoice_items DROP CONSTRAINT invoice_items_contract_product_id_fk;
ALTER TABLE billing.invoice_items ADD CONSTRAINT invoice_items_contract_product_id_fk 
    FOREIGN KEY (contract_product_id) REFERENCES products.contract_products(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE billing.invoice_items DROP CONSTRAINT invoice_items_product_id_fk;
ALTER TABLE billing.invoice_items ADD CONSTRAINT invoice_items_product_id_fk 
    FOREIGN KEY (product_id) REFERENCES products.products(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE billing.invoice_payments DROP CONSTRAINT invoice_payments_invoice_id_fk;
ALTER TABLE billing.invoice_payments ADD CONSTRAINT invoice_payments_invoice_id_fk 
    FOREIGN KEY (invoice_id) REFERENCES billing.invoices(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE billing.invoice_payments DROP CONSTRAINT invoice_payments_payment_account_id_fk;
ALTER TABLE billing.invoice_payments ADD CONSTRAINT invoice_payments_payment_account_id_fk 
    FOREIGN KEY (payment_account_id) REFERENCES billing.payment_accounts(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE billing.invoice_payments DROP CONSTRAINT invoice_payments_payment_method_id_fk;
ALTER TABLE billing.invoice_payments ADD CONSTRAINT invoice_payments_payment_method_id_fk 
    FOREIGN KEY (payment_method_id) REFERENCES billing.payment_methods(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

-- =============================================================================
-- 5. PROSPECTS AND LEAD MANAGEMENT (customers schema)
-- =============================================================================

-- Prospects table for future clients
CREATE TABLE customers.prospects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name VARCHAR(200) NOT NULL,
    contact_name VARCHAR(200),
    email VARCHAR(256),
    phone VARCHAR(20),
    website VARCHAR(255),
    industry VARCHAR(100),
    company_size VARCHAR(50), -- References catalog_options
    lead_source VARCHAR(50), -- References catalog_options  
    status VARCHAR(50) NOT NULL, -- References catalog_options (Lead, Qualified, etc)
    assigned_sales_rep_id UUID REFERENCES auth.users(id),
    estimated_value NUMERIC(12,2),
    estimated_close_date DATE,
    notes TEXT,
    priority VARCHAR(20) DEFAULT 'MEDIUM', -- References catalog_options
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP,
    last_contacted_at TIMESTAMP,
    next_follow_up_date DATE
);

-- Index for performance
CREATE INDEX idx_prospects_status ON customers.prospects(status);
CREATE INDEX idx_prospects_assigned_sales_rep ON customers.prospects(assigned_sales_rep_id);
CREATE INDEX idx_prospects_next_follow_up ON customers.prospects(next_follow_up_date);

-- =============================================================================
-- 6. SALES PIPELINE SYSTEM (sales schema)
-- =============================================================================

-- Sales opportunities
CREATE TABLE sales.opportunities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    customer_id UUID REFERENCES customers.customers(id),
    prospect_id UUID REFERENCES customers.prospects(id),
    assigned_sales_rep_id UUID REFERENCES auth.users(id),
    stage VARCHAR(50) NOT NULL, -- References catalog_options
    probability NUMERIC(5,2) DEFAULT 0 CHECK (probability >= 0 AND probability <= 100),
    estimated_value NUMERIC(12,2) NOT NULL DEFAULT 0,
    actual_value NUMERIC(12,2),
    estimated_close_date DATE,
    actual_close_date DATE,
    lead_source VARCHAR(50), -- References catalog_options
    priority VARCHAR(20) DEFAULT 'MEDIUM', -- References catalog_options
    status VARCHAR(20) DEFAULT 'OPEN', -- OPEN, WON, LOST, CANCELLED
    lost_reason TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP,
    last_activity_date TIMESTAMP,
    next_follow_up_date DATE,
    CONSTRAINT opportunities_customer_or_prospect_check 
        CHECK ((customer_id IS NOT NULL) OR (prospect_id IS NOT NULL))
);

-- Opportunity products/services
CREATE TABLE sales.opportunity_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    opportunity_id UUID NOT NULL REFERENCES sales.opportunities(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products.products(id),
    quantity INTEGER DEFAULT 1 NOT NULL,
    unit_price NUMERIC(10,4) NOT NULL,
    total_price NUMERIC(12,4) NOT NULL,
    discount_percentage NUMERIC(5,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

-- Proposals management
CREATE TABLE sales.proposals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    proposal_number VARCHAR(50) UNIQUE NOT NULL,
    opportunity_id UUID REFERENCES sales.opportunities(id),
    customer_id UUID REFERENCES customers.customers(id),
    prospect_id UUID REFERENCES customers.prospects(id),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    total_amount NUMERIC(12,4) NOT NULL DEFAULT 0,
    currency_id UUID REFERENCES billing.currencies(id),
    status VARCHAR(50) DEFAULT 'DRAFT', -- References catalog_options (DRAFT, SENT, REVIEWED, APPROVED, REJECTED, EXPIRED)
    valid_until DATE,
    sent_date DATE,
    reviewed_date DATE,
    decision_date DATE,
    rejection_reason TEXT,
    version INTEGER DEFAULT 1 NOT NULL,
    parent_proposal_id UUID REFERENCES sales.proposals(id),
    created_by UUID REFERENCES auth.users(id),
    approved_by UUID REFERENCES auth.users(id),
    file_url VARCHAR(500),
    terms_and_conditions TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP,
    CONSTRAINT proposals_customer_or_prospect_check 
        CHECK ((customer_id IS NOT NULL) OR (prospect_id IS NOT NULL))
);

-- Proposal items/products
CREATE TABLE sales.proposal_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    proposal_id UUID NOT NULL REFERENCES sales.proposals(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products.products(id),
    description VARCHAR(300) NOT NULL,
    quantity INTEGER DEFAULT 1 NOT NULL,
    unit_price NUMERIC(10,4) NOT NULL,
    total_price NUMERIC(12,4) NOT NULL,
    discount_percentage NUMERIC(5,2) DEFAULT 0,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

-- Interactions/communications tracking
CREATE TABLE sales.interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customers.customers(id),
    prospect_id UUID REFERENCES customers.prospects(id),
    opportunity_id UUID REFERENCES sales.opportunities(id),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    interaction_type VARCHAR(50) NOT NULL, -- References catalog_options (call, email, meeting, demo, etc)
    subject VARCHAR(200),
    summary TEXT,
    interaction_date TIMESTAMP DEFAULT NOW() NOT NULL,
    duration_minutes INTEGER,
    outcome VARCHAR(50), -- References catalog_options
    next_action VARCHAR(200),
    next_action_date DATE,
    channel VARCHAR(50), -- References catalog_options (phone, email, in-person, video, etc)
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP,
    CONSTRAINT interactions_contact_check 
        CHECK ((customer_id IS NOT NULL) OR (prospect_id IS NOT NULL))
);

-- Detailed interaction notes
CREATE TABLE sales.interaction_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    interaction_id UUID NOT NULL REFERENCES sales.interactions(id) ON DELETE CASCADE,
    note_text TEXT NOT NULL,
    note_type VARCHAR(50) DEFAULT 'GENERAL', -- References catalog_options
    is_internal BOOLEAN DEFAULT false, -- Internal notes vs client-facing
    created_by UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

-- =============================================================================
-- 7. RENEWAL MANAGEMENT (customers schema)
-- =============================================================================

-- Renewal alerts and tracking
CREATE TABLE customers.renewal_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL REFERENCES products.contracts(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers.customers(id),
    renewal_date DATE NOT NULL,
    alert_days_before INTEGER NOT NULL, -- 90, 60, 30, etc.
    alert_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING', -- References catalog_options (PENDING, SENT, ACKNOWLEDGED, COMPLETED, CANCELLED)
    alert_type VARCHAR(20) DEFAULT 'EMAIL', -- References catalog_options
    sent_date TIMESTAMP,
    acknowledged_date TIMESTAMP,
    assigned_to UUID REFERENCES auth.users(id),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

-- Index for renewal alerts
CREATE INDEX idx_renewal_alerts_alert_date ON customers.renewal_alerts(alert_date);
CREATE INDEX idx_renewal_alerts_status ON customers.renewal_alerts(status);
CREATE INDEX idx_renewal_alerts_assigned_to ON customers.renewal_alerts(assigned_to);

-- =============================================================================
-- 8. DOCUMENT MANAGEMENT (support schema)
-- =============================================================================

-- Enhanced document management
CREATE TABLE support.documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customers.customers(id),
    prospect_id UUID REFERENCES customers.prospects(id),
    contract_id UUID REFERENCES products.contracts(id),
    proposal_id UUID REFERENCES sales.proposals(id),
    opportunity_id UUID REFERENCES sales.opportunities(id),
    document_type VARCHAR(50) NOT NULL, -- References catalog_options (CONTRACT, PROPOSAL, NDA, AMENDMENT, etc)
    title VARCHAR(200) NOT NULL,
    description TEXT,
    file_url VARCHAR(500),
    file_name VARCHAR(255),
    file_size_bytes BIGINT,
    mime_type VARCHAR(100),
    version INTEGER DEFAULT 1 NOT NULL,
    parent_document_id UUID REFERENCES support.documents(id),
    status VARCHAR(50) DEFAULT 'DRAFT', -- References catalog_options (DRAFT, PENDING_REVIEW, APPROVED, SIGNED, REJECTED, EXPIRED)
    is_signed BOOLEAN DEFAULT false,
    signature_date TIMESTAMP,
    signed_by VARCHAR(200),
    signature_method VARCHAR(50), -- References catalog_options (DIGITAL, PHYSICAL, ELECTRONIC)
    expiry_date DATE,
    created_by UUID NOT NULL REFERENCES auth.users(id),
    approved_by UUID REFERENCES auth.users(id),
    tags TEXT[], -- Array of tags for categorization
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

-- Document approval workflow
CREATE TABLE support.document_approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES support.documents(id) ON DELETE CASCADE,
    approver_id UUID NOT NULL REFERENCES auth.users(id),
    approval_step INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED
    approved_date TIMESTAMP,
    comments TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

-- =============================================================================
-- 9. SUPPORT PAYMENT TRACKING ENHANCEMENTS (billing schema)
-- =============================================================================

-- Customer support services tracking
CREATE TABLE billing.customer_support_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers.customers(id) ON DELETE CASCADE,
    support_type VARCHAR(50) NOT NULL, -- References catalog_options (BASIC, PREMIUM, ENTERPRISE)
    is_active BOOLEAN DEFAULT true,
    monthly_fee NUMERIC(10,4),
    support_hours_included INTEGER DEFAULT 0,
    support_hours_used INTEGER DEFAULT 0,
    billing_frequency VARCHAR(20) DEFAULT 'MONTHLY', -- References catalog_options
    start_date DATE NOT NULL,
    end_date DATE,
    auto_renew BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

-- Track support incidents/tickets
CREATE TABLE support.support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id UUID NOT NULL REFERENCES customers.customers(id),
    support_service_id UUID REFERENCES billing.customer_support_services(id),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    priority VARCHAR(20) DEFAULT 'MEDIUM', -- References catalog_options
    severity VARCHAR(20) DEFAULT 'LOW', -- References catalog_options  
    status VARCHAR(20) DEFAULT 'OPEN', -- References catalog_options
    category VARCHAR(50), -- References catalog_options
    assigned_to UUID REFERENCES auth.users(id),
    created_by UUID REFERENCES auth.users(id),
    resolved_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP,
    resolved_at TIMESTAMP,
    estimated_hours NUMERIC(4,2),
    actual_hours NUMERIC(4,2)
);

-- =============================================================================
-- 10. INDEXES FOR PERFORMANCE
-- =============================================================================

-- Sales indexes
CREATE INDEX idx_opportunities_stage ON sales.opportunities(stage);
CREATE INDEX idx_opportunities_assigned_sales_rep ON sales.opportunities(assigned_sales_rep_id);
CREATE INDEX idx_opportunities_customer ON sales.opportunities(customer_id);
CREATE INDEX idx_opportunities_prospect ON sales.opportunities(prospect_id);
CREATE INDEX idx_opportunities_close_date ON sales.opportunities(estimated_close_date);

CREATE INDEX idx_proposals_status ON sales.proposals(status);
CREATE INDEX idx_proposals_opportunity ON sales.proposals(opportunity_id);
CREATE INDEX idx_proposals_valid_until ON sales.proposals(valid_until);

CREATE INDEX idx_interactions_customer ON sales.interactions(customer_id);
CREATE INDEX idx_interactions_prospect ON sales.interactions(prospect_id);
CREATE INDEX idx_interactions_date ON sales.interactions(interaction_date);
CREATE INDEX idx_interactions_type ON sales.interactions(interaction_type);

-- Document indexes
CREATE INDEX idx_documents_customer ON support.documents(customer_id);
CREATE INDEX idx_documents_type ON support.documents(document_type);
CREATE INDEX idx_documents_status ON support.documents(status);
CREATE INDEX idx_documents_created_by ON support.documents(created_by);

-- Support indexes  
CREATE INDEX idx_support_tickets_customer ON support.support_tickets(customer_id);
CREATE INDEX idx_support_tickets_status ON support.support_tickets(status);
CREATE INDEX idx_support_tickets_assigned_to ON support.support_tickets(assigned_to);
CREATE INDEX idx_support_tickets_priority ON support.support_tickets(priority);

-- Billing indexes
CREATE INDEX idx_customer_support_services_customer ON billing.customer_support_services(customer_id);
CREATE INDEX idx_customer_support_services_active ON billing.customer_support_services(is_active);