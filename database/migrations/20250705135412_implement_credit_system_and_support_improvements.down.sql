-- Migration: implement_credit_system_and_support_improvements (DOWN)
-- Description: Revert credit system and support schema improvements

BEGIN;

-- =========================================
-- Phase 1: Remove Data Validation Constraints
-- =========================================

-- Remove credit notes validation
ALTER TABLE billing.credit_notes DROP CONSTRAINT IF EXISTS check_credit_amount_positive;
ALTER TABLE billing.credit_notes DROP CONSTRAINT IF EXISTS check_applied_amount_not_negative;
ALTER TABLE billing.credit_notes DROP CONSTRAINT IF EXISTS check_applied_not_greater_than_credit;
ALTER TABLE billing.credit_notes DROP CONSTRAINT IF EXISTS check_exchange_rate_positive;

-- Remove credit note items validation
ALTER TABLE billing.credit_note_items DROP CONSTRAINT IF EXISTS check_quantity_positive;
ALTER TABLE billing.credit_note_items DROP CONSTRAINT IF EXISTS check_unit_price_not_negative;
ALTER TABLE billing.credit_note_items DROP CONSTRAINT IF EXISTS check_tax_rate_valid;

-- Remove credit applications validation
ALTER TABLE billing.credit_applications DROP CONSTRAINT IF EXISTS check_applied_amount_positive;

-- Remove support tickets validation
ALTER TABLE support.support_tickets DROP CONSTRAINT IF EXISTS check_billable_hours_not_negative;
ALTER TABLE support.support_tickets DROP CONSTRAINT IF EXISTS check_credit_cost_not_negative;
ALTER TABLE support.support_tickets DROP CONSTRAINT IF EXISTS check_hourly_rate_not_negative;

-- =========================================
-- Phase 2: Drop Performance Indexes
-- =========================================

-- Drop credit notes indexes
DROP INDEX IF EXISTS idx_credit_notes_company_id;
DROP INDEX IF EXISTS idx_credit_notes_status;
DROP INDEX IF EXISTS idx_credit_notes_issue_date;
DROP INDEX IF EXISTS idx_credit_notes_organization_id;
DROP INDEX IF EXISTS idx_credit_notes_remaining_amount;

-- Drop credit note items indexes
DROP INDEX IF EXISTS idx_credit_note_items_credit_note_id;
DROP INDEX IF EXISTS idx_credit_note_items_original_invoice_item_id;

-- Drop credit applications indexes
DROP INDEX IF EXISTS idx_credit_applications_credit_note_id;
DROP INDEX IF EXISTS idx_credit_applications_target_invoice_id;
DROP INDEX IF EXISTS idx_credit_applications_status;
DROP INDEX IF EXISTS idx_credit_applications_organization_id;

-- Drop support tickets indexes
DROP INDEX IF EXISTS idx_support_tickets_billable_hours;
DROP INDEX IF EXISTS idx_support_tickets_credit_cost;

-- =========================================
-- Phase 3: Remove Foreign Key Constraints
-- =========================================

-- Remove documents table constraints
ALTER TABLE support.documents DROP CONSTRAINT IF EXISTS documents_approver_id_fkey;

-- Remove credit notes constraints
ALTER TABLE billing.credit_notes DROP CONSTRAINT IF EXISTS credit_notes_company_id_fkey;
ALTER TABLE billing.credit_notes DROP CONSTRAINT IF EXISTS credit_notes_original_invoice_id_fkey;
ALTER TABLE billing.credit_notes DROP CONSTRAINT IF EXISTS credit_notes_currency_id_fkey;
ALTER TABLE billing.credit_notes DROP CONSTRAINT IF EXISTS credit_notes_organization_id_fkey;
ALTER TABLE billing.credit_notes DROP CONSTRAINT IF EXISTS credit_notes_created_by_fkey;
ALTER TABLE billing.credit_notes DROP CONSTRAINT IF EXISTS credit_notes_updated_by_fkey;

-- Remove credit note items constraints
ALTER TABLE billing.credit_note_items DROP CONSTRAINT IF EXISTS credit_note_items_credit_note_id_fkey;
ALTER TABLE billing.credit_note_items DROP CONSTRAINT IF EXISTS credit_note_items_original_invoice_item_id_fkey;
ALTER TABLE billing.credit_note_items DROP CONSTRAINT IF EXISTS credit_note_items_contract_product_id_fkey;
ALTER TABLE billing.credit_note_items DROP CONSTRAINT IF EXISTS credit_note_items_product_id_fkey;

-- Remove credit applications constraints
ALTER TABLE billing.credit_applications DROP CONSTRAINT IF EXISTS credit_applications_credit_note_id_fkey;
ALTER TABLE billing.credit_applications DROP CONSTRAINT IF EXISTS credit_applications_target_invoice_id_fkey;
ALTER TABLE billing.credit_applications DROP CONSTRAINT IF EXISTS credit_applications_organization_id_fkey;
ALTER TABLE billing.credit_applications DROP CONSTRAINT IF EXISTS credit_applications_created_by_fkey;
ALTER TABLE billing.credit_applications DROP CONSTRAINT IF EXISTS credit_applications_updated_by_fkey;

-- =========================================
-- Phase 4: Remove Config Catalog Entries
-- =========================================

-- Remove catalog options
DELETE FROM config.catalog_options WHERE catalog_type_id IN (
    SELECT id FROM config.catalog_types WHERE code IN (
        'CREDIT_STATUS', 'CREDIT_REASON', 'CREDIT_APPLICATION_STATUS', 
        'APPROVAL_STATUS', 'ATTACHMENT_CATEGORY', 'ENTITY_TYPE'
    )
);

-- Remove catalog types
DELETE FROM config.catalog_types WHERE code IN (
    'CREDIT_STATUS', 'CREDIT_REASON', 'CREDIT_APPLICATION_STATUS', 
    'APPROVAL_STATUS', 'ATTACHMENT_CATEGORY', 'ENTITY_TYPE'
);

-- =========================================
-- Phase 5: Remove Support System Enhancements
-- =========================================

-- Remove billable hours and credit cost fields from support_tickets
ALTER TABLE support.support_tickets DROP COLUMN IF EXISTS billable_hours;
ALTER TABLE support.support_tickets DROP COLUMN IF EXISTS credit_cost;
ALTER TABLE support.support_tickets DROP COLUMN IF EXISTS hourly_rate;
ALTER TABLE support.support_tickets DROP COLUMN IF EXISTS total_cost;

-- =========================================
-- Phase 6: Remove Credit System Tables
-- =========================================

-- Drop credit system tables
DROP TABLE IF EXISTS billing.credit_applications;
DROP TABLE IF EXISTS billing.credit_note_items;
DROP TABLE IF EXISTS billing.credit_notes;

-- =========================================
-- Phase 7: Revert Documents Table Changes
-- =========================================

-- Drop polymorphic indexes
DROP INDEX IF EXISTS idx_documents_entity_type_id;
DROP INDEX IF EXISTS idx_documents_attachment_category;
DROP INDEX IF EXISTS idx_documents_approval_status;
DROP INDEX IF EXISTS idx_documents_approver_id;

-- Remove polymorphic columns from documents table
ALTER TABLE support.documents DROP COLUMN IF EXISTS entity_type;
ALTER TABLE support.documents DROP COLUMN IF EXISTS entity_id;
ALTER TABLE support.documents DROP COLUMN IF EXISTS attachment_category;

-- Remove approval columns from documents table
ALTER TABLE support.documents DROP COLUMN IF EXISTS approval_status;
ALTER TABLE support.documents DROP COLUMN IF EXISTS approval_step;
ALTER TABLE support.documents DROP COLUMN IF EXISTS approver_id;
ALTER TABLE support.documents DROP COLUMN IF EXISTS approved_date;
ALTER TABLE support.documents DROP COLUMN IF EXISTS approval_comments;

-- =========================================
-- Phase 8: Recreate Document Approvals Table
-- =========================================

-- Recreate document_approvals table
CREATE TABLE support.document_approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL,
    approver_id UUID NOT NULL,
    approval_step INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING',
    approved_date TIMESTAMP,
    comments TEXT,
    organization_id UUID,
    company_id UUID,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE
);

-- Recreate foreign key constraints for document_approvals
ALTER TABLE support.document_approvals ADD CONSTRAINT document_approvals_document_id_fkey 
    FOREIGN KEY (document_id) REFERENCES support.documents(id) ON DELETE CASCADE;
ALTER TABLE support.document_approvals ADD CONSTRAINT document_approvals_approver_id_fkey 
    FOREIGN KEY (approver_id) REFERENCES auth.users(id);
ALTER TABLE support.document_approvals ADD CONSTRAINT document_approvals_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE support.document_approvals ADD CONSTRAINT document_approvals_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);

-- Create indexes for document_approvals
CREATE INDEX idx_document_approvals_document_id ON support.document_approvals(document_id);
CREATE INDEX idx_document_approvals_approver_id ON support.document_approvals(approver_id);
CREATE INDEX idx_document_approvals_status ON support.document_approvals(status);

COMMIT;