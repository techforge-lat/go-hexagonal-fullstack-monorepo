-- Fresh Database Schema with CRM functionality
-- Clean implementation without legacy dependencies

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

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
-- 3. AUTHENTICATION SCHEMA (auth)
-- =============================================================================

-- Resources table
CREATE TABLE auth.resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

-- Resource actions
CREATE TABLE auth.resource_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID NOT NULL REFERENCES auth.resources(id) ON DELETE RESTRICT,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP,
    CONSTRAINT resource_actions_resource_code_uk UNIQUE (resource_id, code)
);

-- Users table
CREATE TABLE auth.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    origin VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    first_name VARCHAR(100) DEFAULT '' NOT NULL,
    last_name VARCHAR(100),
    picture TEXT,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id),
    deleted_at TIMESTAMP,
    deleted_by UUID REFERENCES auth.users(id)
);

-- Email credentials
CREATE TABLE auth.email_credentials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255),
    is_verified BOOLEAN DEFAULT false NOT NULL,
    verification_token VARCHAR(255),
    verification_expires_at TIMESTAMP,
    password_reset_token VARCHAR(255),
    password_reset_expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id)
);

-- Roles table
CREATE TABLE auth.roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(100) NOT NULL,
    description TEXT,
    customer_id UUID, -- Will reference customers.customers later
    is_system_role BOOLEAN DEFAULT false NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id),
    CONSTRAINT roles_customer_code_uk UNIQUE (customer_id, code)
);

-- User roles
CREATE TABLE auth.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES auth.roles(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES auth.users(id),
    assigned_at TIMESTAMP DEFAULT NOW() NOT NULL,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true NOT NULL,
    CONSTRAINT user_roles_user_role_uk UNIQUE (user_id, role_id)
);

-- Resource role permissions
CREATE TABLE auth.resource_role_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID NOT NULL REFERENCES auth.resources(id) ON DELETE RESTRICT,
    role_id UUID NOT NULL REFERENCES auth.roles(id) ON DELETE CASCADE,
    resource_action_id UUID NOT NULL REFERENCES auth.resource_actions(id) ON DELETE CASCADE,
    is_granted BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    CONSTRAINT resource_role_permissions_uk UNIQUE (resource_id, role_id, resource_action_id)
);

-- =============================================================================
-- 4. CUSTOMERS SCHEMA
-- =============================================================================

-- Main customers table
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
    industry VARCHAR(100), -- References catalog_options
    company_size VARCHAR(50), -- References catalog_options
    status VARCHAR(50) DEFAULT 'ACTIVE' NOT NULL, -- References catalog_options
    is_active BOOLEAN DEFAULT true NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id),
    deleted_at TIMESTAMP,
    deleted_by UUID REFERENCES auth.users(id)
);

-- Customer contacts
CREATE TABLE customers.contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers.customers(id) ON DELETE CASCADE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    mobile VARCHAR(20),
    position VARCHAR(100),
    department VARCHAR(100),
    is_primary BOOLEAN DEFAULT false NOT NULL,
    is_billing_contact BOOLEAN DEFAULT false NOT NULL,
    is_technical_contact BOOLEAN DEFAULT false NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id),
    deleted_at TIMESTAMP,
    deleted_by UUID REFERENCES auth.users(id)
);

-- Customer users (link between customers and auth users)
CREATE TABLE customers.customer_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers.customers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    relationship VARCHAR(50) DEFAULT 'EMPLOYEE' NOT NULL, -- EMPLOYEE, ADMIN, CONTACT
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id),
    CONSTRAINT customer_users_customer_user_uk UNIQUE (customer_id, user_id)
);

-- Prospects table for future clients
CREATE TABLE customers.prospects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name VARCHAR(200) NOT NULL,
    contact_name VARCHAR(200),
    email VARCHAR(256),
    phone VARCHAR(20),
    website VARCHAR(255),
    industry VARCHAR(100), -- References catalog_options
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
    next_follow_up_date DATE,
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id)
);

-- Renewal alerts and tracking
CREATE TABLE customers.renewal_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL, -- Will reference products.contracts
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
    updated_at TIMESTAMP,
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id)
);

-- =============================================================================
-- 5. PRODUCTS SCHEMA
-- =============================================================================

-- Products catalog
CREATE TABLE products.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    code VARCHAR(100) UNIQUE,
    description TEXT,
    category VARCHAR(100), -- References catalog_options
    product_type VARCHAR(50) DEFAULT 'SERVICE', -- SERVICE, PRODUCT, SUBSCRIPTION
    is_active BOOLEAN DEFAULT true NOT NULL,
    is_recurring BOOLEAN DEFAULT false NOT NULL,
    billing_frequency VARCHAR(20), -- References catalog_options (MONTHLY, QUARTERLY, etc)
    setup_fee NUMERIC(10,4) DEFAULT 0,
    base_price NUMERIC(10,4) DEFAULT 0,
    currency_code VARCHAR(3) DEFAULT 'USD',
    tax_rate NUMERIC(5,4) DEFAULT 0,
    features JSONB DEFAULT '[]',
    specifications JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id),
    deleted_at TIMESTAMP,
    deleted_by UUID REFERENCES auth.users(id)
);

-- Product pricing tiers
CREATE TABLE products.product_prices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products.products(id) ON DELETE RESTRICT,
    name VARCHAR(100) NOT NULL,
    tier_level INTEGER DEFAULT 1,
    min_quantity INTEGER DEFAULT 1,
    max_quantity INTEGER,
    unit_price NUMERIC(10,4) NOT NULL,
    setup_fee NUMERIC(10,4) DEFAULT 0,
    currency_code VARCHAR(3) DEFAULT 'USD',
    billing_frequency VARCHAR(20), -- References catalog_options
    is_active BOOLEAN DEFAULT true NOT NULL,
    valid_from DATE,
    valid_until DATE,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id)
);

-- Customer contracts
CREATE TABLE products.contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_number VARCHAR(100) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    owner_customer_id UUID NOT NULL REFERENCES customers.customers(id),
    billing_customer_id UUID NOT NULL REFERENCES customers.customers(id),
    status VARCHAR(50) DEFAULT 'DRAFT', -- References catalog_options
    contract_type VARCHAR(50), -- References catalog_options
    start_date DATE NOT NULL,
    end_date DATE,
    auto_renew BOOLEAN DEFAULT false,
    auto_renew_period VARCHAR(20), -- References catalog_options
    payment_terms VARCHAR(50), -- References catalog_options
    currency_code VARCHAR(3) DEFAULT 'USD',
    total_value NUMERIC(12,4) DEFAULT 0,
    notes TEXT,
    terms_and_conditions TEXT,
    file_url VARCHAR(500),
    is_signed BOOLEAN DEFAULT false,
    signed_date DATE,
    signed_by_customer VARCHAR(200),
    signed_by_company VARCHAR(200),
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id),
    deleted_at TIMESTAMP,
    deleted_by UUID REFERENCES auth.users(id)
);

-- Contract products (products included in contracts)
CREATE TABLE products.contract_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL REFERENCES products.contracts(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products.products(id) ON DELETE RESTRICT,
    product_price_id UUID REFERENCES products.product_prices(id) ON DELETE RESTRICT,
    quantity INTEGER DEFAULT 1 NOT NULL,
    unit_price NUMERIC(10,4) NOT NULL,
    setup_fee NUMERIC(10,4) DEFAULT 0,
    total_price NUMERIC(12,4) NOT NULL,
    discount_percentage NUMERIC(5,2) DEFAULT 0,
    discount_amount NUMERIC(10,4) DEFAULT 0,
    billing_frequency VARCHAR(20), -- References catalog_options
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN DEFAULT true NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id)
);

-- =============================================================================
-- 6. BILLING SCHEMA
-- =============================================================================

-- Currencies
CREATE TABLE billing.currencies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(3) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10),
    exchange_rate NUMERIC(10,6) DEFAULT 1.000000,
    is_base_currency BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

-- Payment methods
CREATE TABLE billing.payment_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

-- Payment accounts
CREATE TABLE billing.payment_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    account_type VARCHAR(50) NOT NULL, -- BANK, CREDIT_CARD, DIGITAL_WALLET, etc
    account_number VARCHAR(100),
    bank_name VARCHAR(200),
    currency_id UUID NOT NULL REFERENCES billing.currencies(id) ON DELETE RESTRICT,
    is_active BOOLEAN DEFAULT true NOT NULL,
    balance NUMERIC(12,4) DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id)
);

-- Suppliers
CREATE TABLE billing.suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_name VARCHAR(200) NOT NULL,
    tax_id VARCHAR(50),
    email VARCHAR(255),
    phone VARCHAR(20),
    address_line_1 VARCHAR(255),
    address_line_2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100),
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id)
);

-- Invoice calculations (pre-invoice calculations)
CREATE TABLE billing.invoice_calculations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    calculation_number VARCHAR(100) UNIQUE NOT NULL,
    billing_customer_id UUID NOT NULL REFERENCES customers.customers(id),
    consumer_customer_id UUID NOT NULL REFERENCES customers.customers(id),
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    calculation_date DATE DEFAULT CURRENT_DATE NOT NULL,
    currency_code VARCHAR(3) DEFAULT 'USD',
    subtotal NUMERIC(12,4) DEFAULT 0,
    tax_amount NUMERIC(12,4) DEFAULT 0,
    discount_amount NUMERIC(12,4) DEFAULT 0,
    total_amount NUMERIC(12,4) DEFAULT 0,
    status VARCHAR(50) DEFAULT 'DRAFT', -- References catalog_options
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id)
);

-- Invoice calculation items
CREATE TABLE billing.invoice_calculation_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_calculation_id UUID NOT NULL REFERENCES billing.invoice_calculations(id) ON DELETE CASCADE,
    contract_product_id UUID NOT NULL REFERENCES products.contract_products(id) ON DELETE RESTRICT,
    description VARCHAR(300) NOT NULL,
    quantity NUMERIC(10,3) DEFAULT 1 NOT NULL,
    unit_price NUMERIC(10,4) NOT NULL,
    total_price NUMERIC(12,4) NOT NULL,
    tax_rate NUMERIC(5,4) DEFAULT 0,
    tax_amount NUMERIC(10,4) DEFAULT 0,
    discount_percentage NUMERIC(5,2) DEFAULT 0,
    discount_amount NUMERIC(10,4) DEFAULT 0,
    billing_period_start DATE,
    billing_period_end DATE,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

-- Invoices
CREATE TABLE billing.invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_number VARCHAR(100) UNIQUE NOT NULL,
    billing_customer_id UUID NOT NULL REFERENCES customers.customers(id),
    owner_customer_id UUID NOT NULL REFERENCES customers.customers(id),
    invoice_calculation_id UUID REFERENCES billing.invoice_calculations(id),
    supplier_id UUID NOT NULL REFERENCES billing.suppliers(id),
    invoice_date DATE DEFAULT CURRENT_DATE NOT NULL,
    due_date DATE NOT NULL,
    currency_code VARCHAR(3) DEFAULT 'USD',
    subtotal NUMERIC(12,4) DEFAULT 0,
    tax_amount NUMERIC(12,4) DEFAULT 0,
    discount_amount NUMERIC(12,4) DEFAULT 0,
    total_amount NUMERIC(12,4) DEFAULT 0,
    paid_amount NUMERIC(12,4) DEFAULT 0,
    balance_due NUMERIC(12,4) DEFAULT 0,
    status VARCHAR(50) DEFAULT 'DRAFT', -- References catalog_options (DRAFT, SENT, PAID, OVERDUE, CANCELLED)
    payment_status VARCHAR(50) DEFAULT 'UNPAID', -- References catalog_options
    payment_terms VARCHAR(50), -- References catalog_options
    notes TEXT,
    file_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id)
);

-- Invoice items
CREATE TABLE billing.invoice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES billing.invoices(id) ON DELETE RESTRICT,
    contract_product_id UUID REFERENCES products.contract_products(id) ON DELETE RESTRICT,
    product_id UUID REFERENCES products.products(id) ON DELETE RESTRICT,
    description VARCHAR(300) NOT NULL,
    quantity NUMERIC(10,3) DEFAULT 1 NOT NULL,
    unit_price NUMERIC(10,4) NOT NULL,
    total_price NUMERIC(12,4) NOT NULL,
    tax_rate NUMERIC(5,4) DEFAULT 0,
    tax_amount NUMERIC(10,4) DEFAULT 0,
    discount_percentage NUMERIC(5,2) DEFAULT 0,
    discount_amount NUMERIC(10,4) DEFAULT 0,
    billing_period_start DATE,
    billing_period_end DATE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

-- Invoice payments
CREATE TABLE billing.invoice_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES billing.invoices(id) ON DELETE RESTRICT,
    payment_account_id UUID NOT NULL REFERENCES billing.payment_accounts(id) ON DELETE RESTRICT,
    payment_method_id UUID NOT NULL REFERENCES billing.payment_methods(id) ON DELETE RESTRICT,
    payment_date DATE DEFAULT CURRENT_DATE NOT NULL,
    amount NUMERIC(12,4) NOT NULL,
    currency_code VARCHAR(3) DEFAULT 'USD',
    exchange_rate NUMERIC(10,6) DEFAULT 1.000000,
    reference_number VARCHAR(200),
    payment_type VARCHAR(50) DEFAULT 'PAYMENT', -- PAYMENT, DETRACTION, REFUND
    notes TEXT,
    file_url VARCHAR(500), -- Receipt or proof of payment
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id)
);

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
    updated_at TIMESTAMP,
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id)
);

-- =============================================================================
-- 7. SALES SCHEMA
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
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
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
-- 8. SUPPORT SCHEMA
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
-- 9. ADD FOREIGN KEY CONSTRAINTS FOR CROSS-SCHEMA REFERENCES
-- =============================================================================

-- Add foreign key constraints that reference across schemas
ALTER TABLE auth.roles ADD CONSTRAINT roles_customer_id_fk 
    FOREIGN KEY (customer_id) REFERENCES customers.customers(id) ON DELETE CASCADE;

ALTER TABLE customers.renewal_alerts ADD CONSTRAINT renewal_alerts_contract_id_fk 
    FOREIGN KEY (contract_id) REFERENCES products.contracts(id) ON DELETE CASCADE;

-- =============================================================================
-- 10. CREATE INDEXES FOR PERFORMANCE
-- =============================================================================

-- Configuration indexes
CREATE INDEX idx_catalog_options_catalog_type ON config.catalog_options(catalog_type_id);
CREATE INDEX idx_catalog_options_code ON config.catalog_options(code);
CREATE INDEX idx_catalog_options_active ON config.catalog_options(is_active);
CREATE INDEX idx_catalog_options_sort_order ON config.catalog_options(sort_order);
CREATE INDEX idx_catalog_types_code ON config.catalog_types(code);
CREATE INDEX idx_catalog_types_active ON config.catalog_types(is_active);

-- Auth indexes
CREATE INDEX idx_users_active ON auth.users(is_active);
CREATE INDEX idx_users_deleted_at ON auth.users(deleted_at);
CREATE INDEX idx_email_credentials_email ON auth.email_credentials(email);
CREATE INDEX idx_email_credentials_user_id ON auth.email_credentials(user_id);
CREATE INDEX idx_user_roles_user_id ON auth.user_roles(user_id);
CREATE INDEX idx_user_roles_role_id ON auth.user_roles(role_id);

-- Customer indexes
CREATE INDEX idx_customers_business_name ON customers.customers(business_name);
CREATE INDEX idx_customers_tax_id ON customers.customers(tax_id);
CREATE INDEX idx_customers_status ON customers.customers(status);
CREATE INDEX idx_customers_active ON customers.customers(is_active);
CREATE INDEX idx_customers_deleted_at ON customers.customers(deleted_at);
CREATE INDEX idx_contacts_customer_id ON customers.contacts(customer_id);
CREATE INDEX idx_contacts_email ON customers.contacts(email);
CREATE INDEX idx_customer_users_customer_id ON customers.customer_users(customer_id);
CREATE INDEX idx_customer_users_user_id ON customers.customer_users(user_id);

-- Prospect indexes
CREATE INDEX idx_prospects_status ON customers.prospects(status);
CREATE INDEX idx_prospects_assigned_sales_rep ON customers.prospects(assigned_sales_rep_id);
CREATE INDEX idx_prospects_next_follow_up ON customers.prospects(next_follow_up_date);
CREATE INDEX idx_prospects_company_name ON customers.prospects(company_name);

-- Renewal indexes
CREATE INDEX idx_renewal_alerts_alert_date ON customers.renewal_alerts(alert_date);
CREATE INDEX idx_renewal_alerts_status ON customers.renewal_alerts(status);
CREATE INDEX idx_renewal_alerts_assigned_to ON customers.renewal_alerts(assigned_to);
CREATE INDEX idx_renewal_alerts_customer_id ON customers.renewal_alerts(customer_id);

-- Product indexes
CREATE INDEX idx_products_code ON products.products(code);
CREATE INDEX idx_products_name ON products.products(name);
CREATE INDEX idx_products_active ON products.products(is_active);
CREATE INDEX idx_product_prices_product_id ON products.product_prices(product_id);
CREATE INDEX idx_contracts_number ON products.contracts(contract_number);
CREATE INDEX idx_contracts_owner_customer ON products.contracts(owner_customer_id);
CREATE INDEX idx_contracts_billing_customer ON products.contracts(billing_customer_id);
CREATE INDEX idx_contracts_status ON products.contracts(status);
CREATE INDEX idx_contract_products_contract_id ON products.contract_products(contract_id);
CREATE INDEX idx_contract_products_product_id ON products.contract_products(product_id);

-- Billing indexes
CREATE INDEX idx_currencies_code ON billing.currencies(code);
CREATE INDEX idx_payment_accounts_active ON billing.payment_accounts(is_active);
CREATE INDEX idx_invoices_number ON billing.invoices(invoice_number);
CREATE INDEX idx_invoices_billing_customer ON billing.invoices(billing_customer_id);
CREATE INDEX idx_invoices_status ON billing.invoices(status);
CREATE INDEX idx_invoices_due_date ON billing.invoices(due_date);
CREATE INDEX idx_invoice_items_invoice_id ON billing.invoice_items(invoice_id);
CREATE INDEX idx_invoice_payments_invoice_id ON billing.invoice_payments(invoice_id);
CREATE INDEX idx_invoice_payments_date ON billing.invoice_payments(payment_date);
CREATE INDEX idx_customer_support_services_customer ON billing.customer_support_services(customer_id);
CREATE INDEX idx_customer_support_services_active ON billing.customer_support_services(is_active);

-- Sales indexes
CREATE INDEX idx_opportunities_stage ON sales.opportunities(stage);
CREATE INDEX idx_opportunities_assigned_sales_rep ON sales.opportunities(assigned_sales_rep_id);
CREATE INDEX idx_opportunities_customer ON sales.opportunities(customer_id);
CREATE INDEX idx_opportunities_prospect ON sales.opportunities(prospect_id);
CREATE INDEX idx_opportunities_close_date ON sales.opportunities(estimated_close_date);
CREATE INDEX idx_opportunities_status ON sales.opportunities(status);
CREATE INDEX idx_proposals_status ON sales.proposals(status);
CREATE INDEX idx_proposals_opportunity ON sales.proposals(opportunity_id);
CREATE INDEX idx_proposals_valid_until ON sales.proposals(valid_until);
CREATE INDEX idx_proposals_number ON sales.proposals(proposal_number);
CREATE INDEX idx_interactions_customer ON sales.interactions(customer_id);
CREATE INDEX idx_interactions_prospect ON sales.interactions(prospect_id);
CREATE INDEX idx_interactions_date ON sales.interactions(interaction_date);
CREATE INDEX idx_interactions_type ON sales.interactions(interaction_type);

-- Support indexes  
CREATE INDEX idx_documents_customer ON support.documents(customer_id);
CREATE INDEX idx_documents_type ON support.documents(document_type);
CREATE INDEX idx_documents_status ON support.documents(status);
CREATE INDEX idx_documents_created_by ON support.documents(created_by);
CREATE INDEX idx_support_tickets_customer ON support.support_tickets(customer_id);
CREATE INDEX idx_support_tickets_status ON support.support_tickets(status);
CREATE INDEX idx_support_tickets_assigned_to ON support.support_tickets(assigned_to);
CREATE INDEX idx_support_tickets_priority ON support.support_tickets(priority);
CREATE INDEX idx_support_tickets_number ON support.support_tickets(ticket_number);