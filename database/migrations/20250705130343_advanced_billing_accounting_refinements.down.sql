-- Migration: advanced_billing_accounting_refinements (DOWN)
-- Description: Revert advanced billing and accounting schema refinements

BEGIN;

-- 1. Recreate payment_methods table
CREATE TABLE billing.payment_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    organization_id UUID,
    company_id UUID
);

-- Recreate payment methods indexes and constraints
CREATE INDEX idx_payment_methods_company_id ON billing.payment_methods(company_id);
CREATE INDEX idx_payment_methods_organization_id ON billing.payment_methods(organization_id);
CREATE INDEX idx_payment_methods_org_customer ON billing.payment_methods(organization_id, company_id);
ALTER TABLE billing.payment_methods ADD CONSTRAINT payment_methods_code_key UNIQUE (code);

-- 2. Drop foreign key constraints created in the up migration
-- Bank accounts constraints
ALTER TABLE accounting.bank_accounts DROP CONSTRAINT IF EXISTS bank_accounts_bank_id_fkey;
ALTER TABLE accounting.bank_accounts DROP CONSTRAINT IF EXISTS bank_accounts_currency_id_fkey;
ALTER TABLE accounting.bank_accounts DROP CONSTRAINT IF EXISTS bank_accounts_company_id_fkey;
ALTER TABLE accounting.bank_accounts DROP CONSTRAINT IF EXISTS bank_accounts_organization_id_fkey;
ALTER TABLE accounting.bank_accounts DROP CONSTRAINT IF EXISTS bank_accounts_created_by_fkey;
ALTER TABLE accounting.bank_accounts DROP CONSTRAINT IF EXISTS bank_accounts_updated_by_fkey;

-- Invoice imports constraints
ALTER TABLE billing.invoice_imports DROP CONSTRAINT IF EXISTS invoice_imports_company_id_fkey;
ALTER TABLE billing.invoice_imports DROP CONSTRAINT IF EXISTS invoice_imports_organization_id_fkey;
ALTER TABLE billing.invoice_imports DROP CONSTRAINT IF EXISTS invoice_imports_created_by_fkey;
ALTER TABLE billing.invoice_imports DROP CONSTRAINT IF EXISTS invoice_imports_updated_by_fkey;

ALTER TABLE billing.invoice_import_items DROP CONSTRAINT IF EXISTS invoice_import_items_invoice_import_id_fkey;
ALTER TABLE billing.invoice_import_items DROP CONSTRAINT IF EXISTS invoice_import_items_contract_product_id_fkey;
ALTER TABLE billing.invoice_import_items DROP CONSTRAINT IF EXISTS invoice_import_items_company_id_fkey;
ALTER TABLE billing.invoice_import_items DROP CONSTRAINT IF EXISTS invoice_import_items_organization_id_fkey;

-- Company_id constraints
ALTER TABLE billing.customer_support_services DROP CONSTRAINT IF EXISTS customer_support_services_company_id_fkey;
ALTER TABLE billing.invoice_items DROP CONSTRAINT IF EXISTS invoice_items_company_id_fkey;
ALTER TABLE billing.invoice_payments DROP CONSTRAINT IF EXISTS invoice_payments_company_id_fkey;
ALTER TABLE billing.payment_methods DROP CONSTRAINT IF EXISTS payment_methods_company_id_fkey;
ALTER TABLE sales.interaction_notes DROP CONSTRAINT IF EXISTS interaction_notes_company_id_fkey;
ALTER TABLE sales.pipeline DROP CONSTRAINT IF EXISTS pipeline_company_id_fkey;
ALTER TABLE support.document_approvals DROP CONSTRAINT IF EXISTS document_approvals_company_id_fkey;
ALTER TABLE support.documents DROP CONSTRAINT IF EXISTS documents_company_id_fkey;
ALTER TABLE support.support_tickets DROP CONSTRAINT IF EXISTS support_tickets_company_id_fkey;

-- Other constraints
ALTER TABLE billing.invoice_payments DROP CONSTRAINT IF EXISTS invoice_payments_payment_account_id_fkey;
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_invoice_calculation_id_fkey;

-- 3. Restore bank_name column to bank_accounts and populate from banks table
ALTER TABLE accounting.bank_accounts ADD COLUMN bank_name VARCHAR(200);

-- Populate bank_name from banks table
UPDATE accounting.bank_accounts ba 
SET bank_name = b.name 
FROM accounting.banks b 
WHERE ba.bank_id = b.id;

-- Remove bank_id column
ALTER TABLE accounting.bank_accounts DROP COLUMN IF EXISTS bank_id;

-- 4. Restore invoice_imports structure
ALTER TABLE billing.invoice_imports DROP COLUMN IF EXISTS company_id;
ALTER TABLE billing.invoice_imports ADD COLUMN billing_customer_id UUID NOT NULL DEFAULT gen_random_uuid();
ALTER TABLE billing.invoice_imports ADD COLUMN consumer_customer_id UUID NOT NULL DEFAULT gen_random_uuid();

-- 5. Rename company_id columns back to customer_id
ALTER TABLE billing.customer_support_services RENAME COLUMN company_id TO customer_id;
ALTER TABLE billing.invoice_items RENAME COLUMN company_id TO customer_id;
ALTER TABLE billing.invoice_payments RENAME COLUMN company_id TO customer_id;
ALTER TABLE billing.payment_methods RENAME COLUMN company_id TO customer_id;
ALTER TABLE sales.interaction_notes RENAME COLUMN company_id TO customer_id;
ALTER TABLE sales.pipeline RENAME COLUMN company_id TO customer_id;
ALTER TABLE support.document_approvals RENAME COLUMN company_id TO customer_id;
ALTER TABLE support.documents RENAME COLUMN company_id TO customer_id;
ALTER TABLE support.support_tickets RENAME COLUMN company_id TO customer_id;
ALTER TABLE accounting.bank_accounts RENAME COLUMN company_id TO customer_id;
ALTER TABLE billing.invoice_import_items RENAME COLUMN company_id TO customer_id;

-- 6. Move tables back to original schemas and names
ALTER TABLE billing.invoice_imports RENAME TO invoice_calculations;
ALTER TABLE billing.invoice_calculations SET SCHEMA accounting;

ALTER TABLE billing.invoice_import_items RENAME TO invoice_calculation_items;
ALTER TABLE billing.invoice_calculation_items SET SCHEMA accounting;

ALTER TABLE accounting.bank_accounts RENAME TO payment_accounts;
ALTER TABLE accounting.payment_accounts SET SCHEMA billing;

-- 7. Drop accounting.banks table
DROP TABLE IF EXISTS accounting.banks;

-- 8. Recreate original foreign key constraints
-- Payment methods constraints
ALTER TABLE billing.payment_methods ADD CONSTRAINT payment_methods_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.payment_methods ADD CONSTRAINT payment_methods_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);

-- Payment accounts constraints
ALTER TABLE billing.payment_accounts ADD CONSTRAINT payment_accounts_currency_id_fkey 
    FOREIGN KEY (currency_id) REFERENCES accounting.currencies(id) ON DELETE RESTRICT;
ALTER TABLE billing.payment_accounts ADD CONSTRAINT payment_accounts_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.payment_accounts ADD CONSTRAINT payment_accounts_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE billing.payment_accounts ADD CONSTRAINT payment_accounts_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE billing.payment_accounts ADD CONSTRAINT payment_accounts_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

-- Invoice calculations constraints
ALTER TABLE accounting.invoice_calculations ADD CONSTRAINT invoice_calculations_billing_customer_id_fkey 
    FOREIGN KEY (billing_customer_id) REFERENCES relationships.companies(id);
ALTER TABLE accounting.invoice_calculations ADD CONSTRAINT invoice_calculations_consumer_customer_id_fkey 
    FOREIGN KEY (consumer_customer_id) REFERENCES relationships.companies(id);
ALTER TABLE accounting.invoice_calculations ADD CONSTRAINT invoice_calculations_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE accounting.invoice_calculations ADD CONSTRAINT invoice_calculations_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE accounting.invoice_calculations ADD CONSTRAINT invoice_calculations_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

ALTER TABLE accounting.invoice_calculation_items ADD CONSTRAINT invoice_calculation_items_invoice_calculation_id_fkey 
    FOREIGN KEY (invoice_calculation_id) REFERENCES accounting.invoice_calculations(id) ON DELETE CASCADE;
ALTER TABLE accounting.invoice_calculation_items ADD CONSTRAINT invoice_calculation_items_contract_product_id_fkey 
    FOREIGN KEY (contract_product_id) REFERENCES agreements.contract_products(id) ON DELETE RESTRICT;
ALTER TABLE accounting.invoice_calculation_items ADD CONSTRAINT invoice_calculation_items_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES relationships.companies(id);
ALTER TABLE accounting.invoice_calculation_items ADD CONSTRAINT invoice_calculation_items_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);

-- Other customer_id constraints
ALTER TABLE billing.customer_support_services ADD CONSTRAINT customer_support_services_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.invoice_items ADD CONSTRAINT invoice_items_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.invoice_payments ADD CONSTRAINT invoice_payments_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES relationships.companies(id);
ALTER TABLE sales.interaction_notes ADD CONSTRAINT interaction_notes_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES relationships.companies(id);
ALTER TABLE sales.pipeline ADD CONSTRAINT pipeline_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES relationships.companies(id);
ALTER TABLE support.document_approvals ADD CONSTRAINT document_approvals_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES relationships.companies(id);
ALTER TABLE support.documents ADD CONSTRAINT documents_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES relationships.companies(id);
ALTER TABLE support.support_tickets ADD CONSTRAINT support_tickets_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES relationships.companies(id);

-- Billing constraints
ALTER TABLE billing.invoice_payments ADD CONSTRAINT invoice_payments_payment_method_id_fkey 
    FOREIGN KEY (payment_method_id) REFERENCES billing.payment_methods(id) ON DELETE RESTRICT;
ALTER TABLE billing.invoice_payments ADD CONSTRAINT invoice_payments_payment_account_id_fkey 
    FOREIGN KEY (payment_account_id) REFERENCES billing.payment_accounts(id) ON DELETE RESTRICT;
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_invoice_calculation_id_fkey 
    FOREIGN KEY (invoice_calculation_id) REFERENCES accounting.invoice_calculations(id);

-- 9. Remove payment methods catalog entries (optional - commented out to preserve data)
-- DELETE FROM config.catalog_options WHERE catalog_type_id IN (
--     SELECT id FROM config.catalog_types WHERE code = 'payment_methods'
-- );
-- DELETE FROM config.catalog_types WHERE code = 'payment_methods';

COMMIT;