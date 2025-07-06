-- Restore Dropped Tables Migration
-- This migration restores the following tables that were dropped:
-- 1. billing.credit_applications
-- 2. billing.credit_note_items
-- 3. billing.credit_notes
-- 4. billing.customer_support_services
-- 5. support.documents
-- 6. support.support_tickets

BEGIN;

-- Restore billing.credit_notes table
CREATE TABLE billing.credit_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    credit_note_number VARCHAR(100) UNIQUE NOT NULL,
    company_id UUID NOT NULL,
    original_invoice_id UUID,
    credit_amount NUMERIC(12,4) NOT NULL,
    applied_amount NUMERIC(12,4) DEFAULT 0,
    remaining_amount NUMERIC(12,4) GENERATED ALWAYS AS (credit_amount - applied_amount) STORED,
    currency_id UUID NOT NULL,
    exchange_rate NUMERIC(15,6) DEFAULT 1.0,
    reason TEXT,
    notes TEXT,
    status VARCHAR(50) DEFAULT 'PENDING',
    issue_date DATE DEFAULT CURRENT_DATE,
    expiry_date DATE,
    organization_id UUID NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Restore billing.credit_note_items table
CREATE TABLE billing.credit_note_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    credit_note_id UUID NOT NULL,
    original_invoice_item_id UUID,
    contract_product_id UUID,
    product_id UUID,
    description TEXT NOT NULL,
    quantity NUMERIC(10,4) NOT NULL DEFAULT 1,
    unit_price NUMERIC(12,4) NOT NULL,
    line_total NUMERIC(12,4) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    tax_rate NUMERIC(5,4) DEFAULT 0,
    tax_amount NUMERIC(12,4) GENERATED ALWAYS AS (quantity * unit_price * tax_rate) STORED,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE
);

-- Restore billing.credit_applications table
CREATE TABLE billing.credit_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    credit_note_id UUID NOT NULL,
    target_invoice_id UUID,
    applied_amount NUMERIC(12,4) NOT NULL,
    application_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(50) DEFAULT 'PENDING',
    notes TEXT,
    organization_id UUID NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Restore billing.customer_support_services table (recreate based on standard pattern)
CREATE TABLE billing.customer_support_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    service_type VARCHAR(100) NOT NULL,
    service_level VARCHAR(50) NOT NULL,
    monthly_cost NUMERIC(10,4) NOT NULL,
    currency_id UUID NOT NULL,
    is_active BOOLEAN DEFAULT true,
    start_date DATE DEFAULT CURRENT_DATE,
    end_date DATE,
    notes TEXT,
    organization_id UUID NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Restore support.support_tickets table (recreate based on standard pattern)
CREATE TABLE support.support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_number VARCHAR(100) UNIQUE NOT NULL,
    company_id UUID NOT NULL,
    contact_id UUID,
    subject VARCHAR(255) NOT NULL,
    description TEXT,
    priority VARCHAR(50) DEFAULT 'MEDIUM',
    status VARCHAR(50) DEFAULT 'OPEN',
    category VARCHAR(100),
    assigned_to UUID,
    resolution TEXT,
    resolved_at TIMESTAMP WITHOUT TIME ZONE,
    billable_hours NUMERIC(4,2) DEFAULT 0,
    credit_cost NUMERIC(8,4) DEFAULT 0,
    hourly_rate NUMERIC(8,4),
    total_cost NUMERIC(10,4) GENERATED ALWAYS AS (billable_hours * COALESCE(hourly_rate, 0)) STORED,
    organization_id UUID NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Restore support.documents table (recreate based on standard pattern)
CREATE TABLE support.documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_name VARCHAR(255) NOT NULL,
    document_type VARCHAR(100),
    file_path VARCHAR(500),
    file_size BIGINT,
    mime_type VARCHAR(100),
    company_id UUID,
    prospect_id UUID,
    contract_id UUID,
    entity_type VARCHAR(50),
    entity_id UUID,
    attachment_category VARCHAR(50),
    approval_status VARCHAR(20) DEFAULT 'PENDING',
    approval_step INTEGER DEFAULT 1,
    approver_id UUID,
    approved_date TIMESTAMP,
    approval_comments TEXT,
    organization_id UUID NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Restore foreign key constraints

-- Credit notes constraints
ALTER TABLE billing.credit_notes ADD CONSTRAINT credit_notes_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.credit_notes ADD CONSTRAINT credit_notes_original_invoice_id_fkey 
    FOREIGN KEY (original_invoice_id) REFERENCES billing.invoices(id);
ALTER TABLE billing.credit_notes ADD CONSTRAINT credit_notes_currency_id_fkey 
    FOREIGN KEY (currency_id) REFERENCES accounting.currencies(id);
ALTER TABLE billing.credit_notes ADD CONSTRAINT credit_notes_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE billing.credit_notes ADD CONSTRAINT credit_notes_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE billing.credit_notes ADD CONSTRAINT credit_notes_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

-- Credit note items constraints
ALTER TABLE billing.credit_note_items ADD CONSTRAINT credit_note_items_credit_note_id_fkey 
    FOREIGN KEY (credit_note_id) REFERENCES billing.credit_notes(id) ON DELETE CASCADE;
ALTER TABLE billing.credit_note_items ADD CONSTRAINT credit_note_items_original_invoice_item_id_fkey 
    FOREIGN KEY (original_invoice_item_id) REFERENCES billing.invoice_items(id);
ALTER TABLE billing.credit_note_items ADD CONSTRAINT credit_note_items_contract_product_id_fkey 
    FOREIGN KEY (contract_product_id) REFERENCES agreements.contract_products(id);
ALTER TABLE billing.credit_note_items ADD CONSTRAINT credit_note_items_product_id_fkey 
    FOREIGN KEY (product_id) REFERENCES catalog.products(id);

-- Credit applications constraints
ALTER TABLE billing.credit_applications ADD CONSTRAINT credit_applications_credit_note_id_fkey 
    FOREIGN KEY (credit_note_id) REFERENCES billing.credit_notes(id) ON DELETE CASCADE;
ALTER TABLE billing.credit_applications ADD CONSTRAINT credit_applications_target_invoice_id_fkey 
    FOREIGN KEY (target_invoice_id) REFERENCES billing.invoices(id);
ALTER TABLE billing.credit_applications ADD CONSTRAINT credit_applications_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE billing.credit_applications ADD CONSTRAINT credit_applications_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE billing.credit_applications ADD CONSTRAINT credit_applications_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

-- Customer support services constraints
ALTER TABLE billing.customer_support_services ADD CONSTRAINT customer_support_services_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.customer_support_services ADD CONSTRAINT customer_support_services_currency_id_fkey 
    FOREIGN KEY (currency_id) REFERENCES accounting.currencies(id);
ALTER TABLE billing.customer_support_services ADD CONSTRAINT customer_support_services_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE billing.customer_support_services ADD CONSTRAINT customer_support_services_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE billing.customer_support_services ADD CONSTRAINT customer_support_services_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

-- Support tickets constraints
ALTER TABLE support.support_tickets ADD CONSTRAINT support_tickets_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE support.support_tickets ADD CONSTRAINT support_tickets_contact_id_fkey 
    FOREIGN KEY (contact_id) REFERENCES relationships.contacts(id);
ALTER TABLE support.support_tickets ADD CONSTRAINT support_tickets_assigned_to_fkey 
    FOREIGN KEY (assigned_to) REFERENCES auth.users(id);
ALTER TABLE support.support_tickets ADD CONSTRAINT support_tickets_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE support.support_tickets ADD CONSTRAINT support_tickets_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE support.support_tickets ADD CONSTRAINT support_tickets_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

-- Documents constraints
ALTER TABLE support.documents ADD CONSTRAINT documents_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE support.documents ADD CONSTRAINT documents_approver_id_fkey 
    FOREIGN KEY (approver_id) REFERENCES auth.users(id);
ALTER TABLE support.documents ADD CONSTRAINT documents_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE support.documents ADD CONSTRAINT documents_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE support.documents ADD CONSTRAINT documents_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

-- Restore indexes

-- Credit notes indexes
CREATE INDEX idx_credit_notes_company_id ON billing.credit_notes(company_id);
CREATE INDEX idx_credit_notes_status ON billing.credit_notes(status);
CREATE INDEX idx_credit_notes_issue_date ON billing.credit_notes(issue_date);
CREATE INDEX idx_credit_notes_organization_id ON billing.credit_notes(organization_id);
CREATE INDEX idx_credit_notes_remaining_amount ON billing.credit_notes(remaining_amount) WHERE remaining_amount > 0;

-- Credit note items indexes
CREATE INDEX idx_credit_note_items_credit_note_id ON billing.credit_note_items(credit_note_id);
CREATE INDEX idx_credit_note_items_original_invoice_item_id ON billing.credit_note_items(original_invoice_item_id);

-- Credit applications indexes
CREATE INDEX idx_credit_applications_credit_note_id ON billing.credit_applications(credit_note_id);
CREATE INDEX idx_credit_applications_target_invoice_id ON billing.credit_applications(target_invoice_id);
CREATE INDEX idx_credit_applications_status ON billing.credit_applications(status);
CREATE INDEX idx_credit_applications_organization_id ON billing.credit_applications(organization_id);

-- Support tickets indexes
CREATE INDEX idx_support_tickets_company_id ON support.support_tickets(company_id);
CREATE INDEX idx_support_tickets_status ON support.support_tickets(status);
CREATE INDEX idx_support_tickets_priority ON support.support_tickets(priority);
CREATE INDEX idx_support_tickets_assigned_to ON support.support_tickets(assigned_to);
CREATE INDEX idx_support_tickets_organization_id ON support.support_tickets(organization_id);
CREATE INDEX idx_support_tickets_billable_hours ON support.support_tickets(billable_hours) WHERE billable_hours > 0;
CREATE INDEX idx_support_tickets_credit_cost ON support.support_tickets(credit_cost) WHERE credit_cost > 0;

-- Documents indexes
CREATE INDEX idx_documents_entity_type_id ON support.documents(entity_type, entity_id);
CREATE INDEX idx_documents_attachment_category ON support.documents(attachment_category);
CREATE INDEX idx_documents_approval_status ON support.documents(approval_status);
CREATE INDEX idx_documents_approver_id ON support.documents(approver_id);
CREATE INDEX idx_documents_organization_id ON support.documents(organization_id);

-- Restore validation constraints

-- Credit notes validation
ALTER TABLE billing.credit_notes ADD CONSTRAINT check_credit_amount_positive 
    CHECK (credit_amount > 0);
ALTER TABLE billing.credit_notes ADD CONSTRAINT check_applied_amount_not_negative 
    CHECK (applied_amount >= 0);
ALTER TABLE billing.credit_notes ADD CONSTRAINT check_applied_not_greater_than_credit 
    CHECK (applied_amount <= credit_amount);
ALTER TABLE billing.credit_notes ADD CONSTRAINT check_exchange_rate_positive 
    CHECK (exchange_rate > 0);

-- Credit note items validation
ALTER TABLE billing.credit_note_items ADD CONSTRAINT check_quantity_positive 
    CHECK (quantity > 0);
ALTER TABLE billing.credit_note_items ADD CONSTRAINT check_unit_price_not_negative 
    CHECK (unit_price >= 0);
ALTER TABLE billing.credit_note_items ADD CONSTRAINT check_tax_rate_valid 
    CHECK (tax_rate >= 0 AND tax_rate <= 1);

-- Credit applications validation
ALTER TABLE billing.credit_applications ADD CONSTRAINT check_applied_amount_positive 
    CHECK (applied_amount > 0);

-- Support tickets validation
ALTER TABLE support.support_tickets ADD CONSTRAINT check_billable_hours_not_negative 
    CHECK (billable_hours >= 0);
ALTER TABLE support.support_tickets ADD CONSTRAINT check_credit_cost_not_negative 
    CHECK (credit_cost >= 0);
ALTER TABLE support.support_tickets ADD CONSTRAINT check_hourly_rate_not_negative 
    CHECK (hourly_rate >= 0);

COMMIT;