-- Migration: implement_credit_system_and_support_improvements
-- Description: Add credit system for billing and improve support schema by consolidating document approvals

BEGIN;

-- =========================================
-- Phase 1: Consolidate Document Approvals
-- =========================================

-- Drop existing foreign key constraints that will be affected
ALTER TABLE support.document_approvals DROP CONSTRAINT IF EXISTS document_approvals_document_id_fkey;
ALTER TABLE support.document_approvals DROP CONSTRAINT IF EXISTS document_approvals_approver_id_fkey;
ALTER TABLE support.document_approvals DROP CONSTRAINT IF EXISTS document_approvals_organization_id_fkey;
ALTER TABLE support.document_approvals DROP CONSTRAINT IF EXISTS document_approvals_company_id_fkey;

-- Add approval columns to documents table
ALTER TABLE support.documents ADD COLUMN approval_status VARCHAR(20) DEFAULT 'PENDING';
ALTER TABLE support.documents ADD COLUMN approval_step INTEGER DEFAULT 1;
ALTER TABLE support.documents ADD COLUMN approver_id UUID;
ALTER TABLE support.documents ADD COLUMN approved_date TIMESTAMP;
ALTER TABLE support.documents ADD COLUMN approval_comments TEXT;

-- Migrate existing approval data to documents table (take the latest approval record for each document)
UPDATE support.documents SET 
    approval_status = COALESCE(
        (SELECT status FROM support.document_approvals 
         WHERE document_id = support.documents.id 
         ORDER BY approval_step DESC, created_at DESC LIMIT 1), 
        'PENDING'
    ),
    approval_step = COALESCE(
        (SELECT approval_step FROM support.document_approvals 
         WHERE document_id = support.documents.id 
         ORDER BY approval_step DESC, created_at DESC LIMIT 1), 
        1
    ),
    approver_id = (SELECT approver_id FROM support.document_approvals 
                   WHERE document_id = support.documents.id 
                   ORDER BY approval_step DESC, created_at DESC LIMIT 1),
    approved_date = (SELECT approved_date FROM support.document_approvals 
                     WHERE document_id = support.documents.id 
                     ORDER BY approval_step DESC, created_at DESC LIMIT 1),
    approval_comments = (SELECT comments FROM support.document_approvals 
                        WHERE document_id = support.documents.id 
                        ORDER BY approval_step DESC, created_at DESC LIMIT 1);

-- Drop the document_approvals table
DROP TABLE IF EXISTS support.document_approvals;

-- =========================================
-- Phase 2: Generalize Documents as Universal Attachments
-- =========================================

-- Add polymorphic columns to documents table
ALTER TABLE support.documents ADD COLUMN entity_type VARCHAR(50);
ALTER TABLE support.documents ADD COLUMN entity_id UUID;
ALTER TABLE support.documents ADD COLUMN attachment_category VARCHAR(50);

-- Update existing records to use polymorphic columns where possible
UPDATE support.documents SET 
    entity_type = 'COMPANY',
    entity_id = company_id,
    attachment_category = 'COMPANY_DOCUMENT'
WHERE company_id IS NOT NULL;

UPDATE support.documents SET 
    entity_type = 'PROSPECT',
    entity_id = prospect_id,
    attachment_category = 'PROSPECT_DOCUMENT'
WHERE prospect_id IS NOT NULL AND entity_type IS NULL;

UPDATE support.documents SET 
    entity_type = 'CONTRACT',
    entity_id = contract_id,
    attachment_category = 'CONTRACT_DOCUMENT'
WHERE contract_id IS NOT NULL AND entity_type IS NULL;

-- Add indexes for polymorphic queries
CREATE INDEX idx_documents_entity_type_id ON support.documents(entity_type, entity_id);
CREATE INDEX idx_documents_attachment_category ON support.documents(attachment_category);
CREATE INDEX idx_documents_approval_status ON support.documents(approval_status);
CREATE INDEX idx_documents_approver_id ON support.documents(approver_id);

-- =========================================
-- Phase 3: Credit System Implementation
-- =========================================

-- Create credit_notes table
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

-- Create credit_note_items table
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

-- Create credit_applications table
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

-- =========================================
-- Phase 4: Support System Enhancement
-- =========================================

-- Add billable hours and credit cost fields to support_tickets
ALTER TABLE support.support_tickets ADD COLUMN billable_hours NUMERIC(4,2) DEFAULT 0;
ALTER TABLE support.support_tickets ADD COLUMN credit_cost NUMERIC(8,4) DEFAULT 0;
ALTER TABLE support.support_tickets ADD COLUMN hourly_rate NUMERIC(8,4);
ALTER TABLE support.support_tickets ADD COLUMN total_cost NUMERIC(10,4) GENERATED ALWAYS AS (billable_hours * COALESCE(hourly_rate, 0)) STORED;

-- =========================================
-- Phase 5: Add Config Catalog Entries
-- =========================================

-- Add credit system related catalog entries
INSERT INTO config.catalog_types (code, name, description, is_active) VALUES
('CREDIT_STATUS', 'Credit Status', 'Status options for credit notes', true),
('CREDIT_REASON', 'Credit Reason', 'Reason codes for credit notes', true),
('CREDIT_APPLICATION_STATUS', 'Credit Application Status', 'Status options for credit applications', true),
('APPROVAL_STATUS', 'Approval Status', 'Status options for document approvals', true),
('ATTACHMENT_CATEGORY', 'Attachment Category', 'Categories for document attachments', true),
('ENTITY_TYPE', 'Entity Type', 'Entity types for polymorphic relationships', true)
ON CONFLICT (code) DO NOTHING;

-- Add credit status options
INSERT INTO config.catalog_options (catalog_type_id, code, name, description, is_active, sort_order) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'CREDIT_STATUS'), 'DRAFT', 'Draft', 'Credit note in draft status', true, 1),
((SELECT id FROM config.catalog_types WHERE code = 'CREDIT_STATUS'), 'PENDING', 'Pending', 'Credit note pending approval', true, 2),
((SELECT id FROM config.catalog_types WHERE code = 'CREDIT_STATUS'), 'APPROVED', 'Approved', 'Credit note approved', true, 3),
((SELECT id FROM config.catalog_types WHERE code = 'CREDIT_STATUS'), 'APPLIED', 'Applied', 'Credit note fully applied', true, 4),
((SELECT id FROM config.catalog_types WHERE code = 'CREDIT_STATUS'), 'CANCELLED', 'Cancelled', 'Credit note cancelled', true, 5),
((SELECT id FROM config.catalog_types WHERE code = 'CREDIT_STATUS'), 'EXPIRED', 'Expired', 'Credit note expired', true, 6)
ON CONFLICT (catalog_type_id, code) DO NOTHING;

-- Add credit reason options
INSERT INTO config.catalog_options (catalog_type_id, code, name, description, is_active, sort_order) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'CREDIT_REASON'), 'OVERCHARGE', 'Overcharge', 'Customer was overcharged', true, 1),
((SELECT id FROM config.catalog_types WHERE code = 'CREDIT_REASON'), 'DEFECTIVE_PRODUCT', 'Defective Product', 'Product was defective', true, 2),
((SELECT id FROM config.catalog_types WHERE code = 'CREDIT_REASON'), 'SERVICE_ISSUE', 'Service Issue', 'Service delivery issue', true, 3),
((SELECT id FROM config.catalog_types WHERE code = 'CREDIT_REASON'), 'GOODWILL', 'Goodwill', 'Goodwill credit', true, 4),
((SELECT id FROM config.catalog_types WHERE code = 'CREDIT_REASON'), 'CANCELLATION', 'Cancellation', 'Service cancellation', true, 5),
((SELECT id FROM config.catalog_types WHERE code = 'CREDIT_REASON'), 'OTHER', 'Other', 'Other reason', true, 6)
ON CONFLICT (catalog_type_id, code) DO NOTHING;

-- Add approval status options
INSERT INTO config.catalog_options (catalog_type_id, code, name, description, is_active, sort_order) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'APPROVAL_STATUS'), 'PENDING', 'Pending', 'Awaiting approval', true, 1),
((SELECT id FROM config.catalog_types WHERE code = 'APPROVAL_STATUS'), 'APPROVED', 'Approved', 'Approved', true, 2),
((SELECT id FROM config.catalog_types WHERE code = 'APPROVAL_STATUS'), 'REJECTED', 'Rejected', 'Rejected', true, 3),
((SELECT id FROM config.catalog_types WHERE code = 'APPROVAL_STATUS'), 'REVISION_REQUIRED', 'Revision Required', 'Requires revision', true, 4)
ON CONFLICT (catalog_type_id, code) DO NOTHING;

-- Add attachment categories
INSERT INTO config.catalog_options (catalog_type_id, code, name, description, is_active, sort_order) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'ATTACHMENT_CATEGORY'), 'CONTRACT', 'Contract', 'Contract documents', true, 1),
((SELECT id FROM config.catalog_types WHERE code = 'ATTACHMENT_CATEGORY'), 'PROPOSAL', 'Proposal', 'Proposal documents', true, 2),
((SELECT id FROM config.catalog_types WHERE code = 'ATTACHMENT_CATEGORY'), 'INVOICE', 'Invoice', 'Invoice attachments', true, 3),
((SELECT id FROM config.catalog_types WHERE code = 'ATTACHMENT_CATEGORY'), 'SUPPORT_TICKET', 'Support Ticket', 'Support ticket attachments', true, 4),
((SELECT id FROM config.catalog_types WHERE code = 'ATTACHMENT_CATEGORY'), 'COMPANY_DOCUMENT', 'Company Document', 'Company related documents', true, 5),
((SELECT id FROM config.catalog_types WHERE code = 'ATTACHMENT_CATEGORY'), 'PROSPECT_DOCUMENT', 'Prospect Document', 'Prospect related documents', true, 6),
((SELECT id FROM config.catalog_types WHERE code = 'ATTACHMENT_CATEGORY'), 'CREDIT_NOTE', 'Credit Note', 'Credit note attachments', true, 7)
ON CONFLICT (catalog_type_id, code) DO NOTHING;

-- Add entity types
INSERT INTO config.catalog_options (catalog_type_id, code, name, description, is_active, sort_order) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'ENTITY_TYPE'), 'COMPANY', 'Company', 'Company entity', true, 1),
((SELECT id FROM config.catalog_types WHERE code = 'ENTITY_TYPE'), 'PROSPECT', 'Prospect', 'Prospect entity', true, 2),
((SELECT id FROM config.catalog_types WHERE code = 'ENTITY_TYPE'), 'CONTRACT', 'Contract', 'Contract entity', true, 3),
((SELECT id FROM config.catalog_types WHERE code = 'ENTITY_TYPE'), 'INVOICE', 'Invoice', 'Invoice entity', true, 4),
((SELECT id FROM config.catalog_types WHERE code = 'ENTITY_TYPE'), 'SUPPORT_TICKET', 'Support Ticket', 'Support ticket entity', true, 5),
((SELECT id FROM config.catalog_types WHERE code = 'ENTITY_TYPE'), 'CREDIT_NOTE', 'Credit Note', 'Credit note entity', true, 6),
((SELECT id FROM config.catalog_types WHERE code = 'ENTITY_TYPE'), 'CONTACT', 'Contact', 'Contact entity', true, 7)
ON CONFLICT (catalog_type_id, code) DO NOTHING;

-- =========================================
-- Phase 6: Create Foreign Key Constraints
-- =========================================

-- Documents table constraints (updated)
ALTER TABLE support.documents ADD CONSTRAINT documents_approver_id_fkey 
    FOREIGN KEY (approver_id) REFERENCES auth.users(id);

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

-- =========================================
-- Phase 7: Performance Indexes
-- =========================================

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

-- Support tickets indexes (enhanced)
CREATE INDEX idx_support_tickets_billable_hours ON support.support_tickets(billable_hours) WHERE billable_hours > 0;
CREATE INDEX idx_support_tickets_credit_cost ON support.support_tickets(credit_cost) WHERE credit_cost > 0;

-- =========================================
-- Phase 8: Data Validation Constraints
-- =========================================

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