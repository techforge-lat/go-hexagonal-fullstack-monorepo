-- Migration: advanced_billing_accounting_refinements  
-- Description: Advanced billing and accounting schema refinements with config integration

BEGIN;

-- 1. Create payment methods catalog entries in config schema
INSERT INTO config.catalog_types (name, code, description, is_active) VALUES 
('Payment Methods', 'payment_methods', 'Available payment methods for invoices', true)
ON CONFLICT (code) DO NOTHING;

DO $$
DECLARE
    payment_methods_type_id UUID;
BEGIN
    SELECT id INTO payment_methods_type_id FROM config.catalog_types WHERE code = 'payment_methods';
    
    -- Insert payment method options
    INSERT INTO config.catalog_options (catalog_type_id, name, code, description, sort_order, is_active) VALUES
    (payment_methods_type_id, 'Credit Card', 'CREDIT_CARD', 'Credit card payments', 1, true),
    (payment_methods_type_id, 'Bank Transfer', 'BANK_TRANSFER', 'Electronic bank transfers', 2, true),
    (payment_methods_type_id, 'Check', 'CHECK', 'Paper check payments', 3, true),
    (payment_methods_type_id, 'Cash', 'CASH', 'Cash payments', 4, true),
    (payment_methods_type_id, 'Wire Transfer', 'WIRE_TRANSFER', 'Wire transfer payments', 5, true),
    (payment_methods_type_id, 'ACH', 'ACH', 'ACH electronic payments', 6, true)
    ON CONFLICT (catalog_type_id, code) DO NOTHING;
END $$;

-- 2. Create accounting.banks table
CREATE TABLE accounting.banks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    code VARCHAR(50),
    swift_code VARCHAR(11),
    routing_number VARCHAR(50),
    country VARCHAR(100),
    website VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    created_by UUID,
    updated_by UUID
);

-- Create indexes for banks table
CREATE INDEX idx_banks_code ON accounting.banks(code);
CREATE INDEX idx_banks_swift_code ON accounting.banks(swift_code);
CREATE INDEX idx_banks_country ON accounting.banks(country);
CREATE INDEX idx_banks_active ON accounting.banks(is_active);

-- Add foreign key constraints for banks table
ALTER TABLE accounting.banks ADD CONSTRAINT banks_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE accounting.banks ADD CONSTRAINT banks_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

-- 3. Drop foreign key constraints that will be affected
-- Payment methods references
ALTER TABLE billing.invoice_payments DROP CONSTRAINT IF EXISTS invoice_payments_payment_method_id_fkey;

-- Payment accounts references  
ALTER TABLE billing.payment_accounts DROP CONSTRAINT IF EXISTS payment_accounts_currency_id_fkey;
ALTER TABLE billing.payment_accounts DROP CONSTRAINT IF EXISTS payment_accounts_customer_id_fkey;
ALTER TABLE billing.payment_accounts DROP CONSTRAINT IF EXISTS payment_accounts_organization_id_fkey;
ALTER TABLE billing.payment_accounts DROP CONSTRAINT IF EXISTS payment_accounts_created_by_fkey;
ALTER TABLE billing.payment_accounts DROP CONSTRAINT IF EXISTS payment_accounts_updated_by_fkey;
ALTER TABLE billing.invoice_payments DROP CONSTRAINT IF EXISTS invoice_payments_payment_account_id_fkey;

-- Invoice calculations references
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_invoice_calculation_id_fkey;
ALTER TABLE accounting.invoice_calculations DROP CONSTRAINT IF EXISTS invoice_calculations_billing_customer_id_fkey;
ALTER TABLE accounting.invoice_calculations DROP CONSTRAINT IF EXISTS invoice_calculations_consumer_customer_id_fkey;
ALTER TABLE accounting.invoice_calculations DROP CONSTRAINT IF EXISTS invoice_calculations_organization_id_fkey;
ALTER TABLE accounting.invoice_calculations DROP CONSTRAINT IF EXISTS invoice_calculations_created_by_fkey;
ALTER TABLE accounting.invoice_calculations DROP CONSTRAINT IF EXISTS invoice_calculations_updated_by_fkey;

ALTER TABLE accounting.invoice_calculation_items DROP CONSTRAINT IF EXISTS invoice_calculation_items_invoice_calculation_id_fkey;
ALTER TABLE accounting.invoice_calculation_items DROP CONSTRAINT IF EXISTS invoice_calculation_items_contract_product_id_fkey;
ALTER TABLE accounting.invoice_calculation_items DROP CONSTRAINT IF EXISTS invoice_calculation_items_customer_id_fkey;
ALTER TABLE accounting.invoice_calculation_items DROP CONSTRAINT IF EXISTS invoice_calculation_items_organization_id_fkey;

-- Other customer_id constraints that will be renamed
ALTER TABLE billing.customer_support_services DROP CONSTRAINT IF EXISTS customer_support_services_customer_id_fkey;
ALTER TABLE billing.invoice_items DROP CONSTRAINT IF EXISTS invoice_items_customer_id_fkey;
ALTER TABLE billing.invoice_payments DROP CONSTRAINT IF EXISTS invoice_payments_customer_id_fkey;
ALTER TABLE billing.payment_methods DROP CONSTRAINT IF EXISTS payment_methods_customer_id_fkey;
ALTER TABLE sales.interaction_notes DROP CONSTRAINT IF EXISTS interaction_notes_customer_id_fkey;
ALTER TABLE sales.pipeline DROP CONSTRAINT IF EXISTS pipeline_customer_id_fkey;
ALTER TABLE support.document_approvals DROP CONSTRAINT IF EXISTS document_approvals_customer_id_fkey;
ALTER TABLE support.documents DROP CONSTRAINT IF EXISTS documents_customer_id_fkey;
ALTER TABLE support.support_tickets DROP CONSTRAINT IF EXISTS support_tickets_customer_id_fkey;

-- 4. Move payment_accounts to accounting schema and rename to bank_accounts
ALTER TABLE billing.payment_accounts SET SCHEMA accounting;
ALTER TABLE accounting.payment_accounts RENAME TO bank_accounts;

-- 5. Move invoice calculations back to billing schema and rename
ALTER TABLE accounting.invoice_calculations SET SCHEMA billing;
ALTER TABLE billing.invoice_calculations RENAME TO invoice_imports;

ALTER TABLE accounting.invoice_calculation_items SET SCHEMA billing;
ALTER TABLE billing.invoice_calculation_items RENAME TO invoice_import_items;

-- 6. Rename customer_id columns to company_id across all affected tables
ALTER TABLE billing.customer_support_services RENAME COLUMN customer_id TO company_id;
ALTER TABLE billing.invoice_items RENAME COLUMN customer_id TO company_id;
ALTER TABLE billing.invoice_payments RENAME COLUMN customer_id TO company_id;
ALTER TABLE billing.payment_methods RENAME COLUMN customer_id TO company_id;
ALTER TABLE sales.interaction_notes RENAME COLUMN customer_id TO company_id;
ALTER TABLE sales.pipeline RENAME COLUMN customer_id TO company_id;
ALTER TABLE support.document_approvals RENAME COLUMN customer_id TO company_id;
ALTER TABLE support.documents RENAME COLUMN customer_id TO company_id;
ALTER TABLE support.support_tickets RENAME COLUMN customer_id TO company_id;
ALTER TABLE accounting.bank_accounts RENAME COLUMN customer_id TO company_id;
ALTER TABLE billing.invoice_import_items RENAME COLUMN customer_id TO company_id;

-- 7. Simplify invoice_imports table structure
ALTER TABLE billing.invoice_imports DROP COLUMN IF EXISTS billing_customer_id;
ALTER TABLE billing.invoice_imports DROP COLUMN IF EXISTS consumer_customer_id;
ALTER TABLE billing.invoice_imports ADD COLUMN company_id UUID;

-- 8. Add bank_id to bank_accounts and populate from bank_name
ALTER TABLE accounting.bank_accounts ADD COLUMN bank_id UUID;

-- Create banks from existing bank_name data and update bank_accounts
DO $$
DECLARE
    bank_record RECORD;
    new_bank_id UUID;
BEGIN
    -- Insert unique banks from existing bank_name data
    FOR bank_record IN 
        SELECT DISTINCT bank_name 
        FROM accounting.bank_accounts 
        WHERE bank_name IS NOT NULL AND bank_name != ''
    LOOP
        INSERT INTO accounting.banks (name) 
        VALUES (bank_record.bank_name)
        RETURNING id INTO new_bank_id;
        
        -- Update bank_accounts with the new bank_id
        UPDATE accounting.bank_accounts 
        SET bank_id = new_bank_id 
        WHERE bank_name = bank_record.bank_name;
    END LOOP;
END $$;

-- Remove bank_name column as it's now replaced by bank_id
ALTER TABLE accounting.bank_accounts DROP COLUMN IF EXISTS bank_name;

-- 9. Update payment_method_id in invoice_payments to reference config schema
-- This will be handled by application logic during the transition

-- 10. Recreate all foreign key constraints with correct references
-- Bank accounts constraints
ALTER TABLE accounting.bank_accounts ADD CONSTRAINT bank_accounts_bank_id_fkey 
    FOREIGN KEY (bank_id) REFERENCES accounting.banks(id) ON DELETE RESTRICT;
ALTER TABLE accounting.bank_accounts ADD CONSTRAINT bank_accounts_currency_id_fkey 
    FOREIGN KEY (currency_id) REFERENCES accounting.currencies(id) ON DELETE RESTRICT;
ALTER TABLE accounting.bank_accounts ADD CONSTRAINT bank_accounts_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE accounting.bank_accounts ADD CONSTRAINT bank_accounts_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE accounting.bank_accounts ADD CONSTRAINT bank_accounts_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE accounting.bank_accounts ADD CONSTRAINT bank_accounts_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

-- Invoice imports constraints  
ALTER TABLE billing.invoice_imports ADD CONSTRAINT invoice_imports_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.invoice_imports ADD CONSTRAINT invoice_imports_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE billing.invoice_imports ADD CONSTRAINT invoice_imports_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE billing.invoice_imports ADD CONSTRAINT invoice_imports_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

ALTER TABLE billing.invoice_import_items ADD CONSTRAINT invoice_import_items_invoice_import_id_fkey 
    FOREIGN KEY (invoice_calculation_id) REFERENCES billing.invoice_imports(id) ON DELETE CASCADE;
ALTER TABLE billing.invoice_import_items ADD CONSTRAINT invoice_import_items_contract_product_id_fkey 
    FOREIGN KEY (contract_product_id) REFERENCES agreements.contract_products(id) ON DELETE RESTRICT;
ALTER TABLE billing.invoice_import_items ADD CONSTRAINT invoice_import_items_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.invoice_import_items ADD CONSTRAINT invoice_import_items_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);

-- Other company_id constraints
ALTER TABLE billing.customer_support_services ADD CONSTRAINT customer_support_services_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.invoice_items ADD CONSTRAINT invoice_items_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.invoice_payments ADD CONSTRAINT invoice_payments_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.payment_methods ADD CONSTRAINT payment_methods_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE sales.interaction_notes ADD CONSTRAINT interaction_notes_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE sales.pipeline ADD CONSTRAINT pipeline_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE support.document_approvals ADD CONSTRAINT document_approvals_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE support.documents ADD CONSTRAINT documents_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE support.support_tickets ADD CONSTRAINT support_tickets_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);

-- Update invoice payments to reference bank accounts
ALTER TABLE billing.invoice_payments ADD CONSTRAINT invoice_payments_payment_account_id_fkey 
    FOREIGN KEY (payment_account_id) REFERENCES accounting.bank_accounts(id) ON DELETE RESTRICT;

-- Update invoices to reference invoice imports
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_invoice_calculation_id_fkey 
    FOREIGN KEY (invoice_calculation_id) REFERENCES billing.invoice_imports(id);

-- 11. Drop payment_methods table (data should be migrated to config schema by application)
DROP TABLE IF EXISTS billing.payment_methods;

COMMIT;