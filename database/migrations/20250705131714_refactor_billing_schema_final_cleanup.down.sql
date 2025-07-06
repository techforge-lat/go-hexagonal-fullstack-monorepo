-- Migration: refactor_billing_schema_final_cleanup (DOWN)
-- Description: Revert final billing schema cleanup

BEGIN;

-- 1. Drop foreign key constraints created in the up migration
-- Exchange rates constraints
ALTER TABLE accounting.exchange_rates DROP CONSTRAINT IF EXISTS exchange_rates_from_currency_id_fkey;
ALTER TABLE accounting.exchange_rates DROP CONSTRAINT IF EXISTS exchange_rates_to_currency_id_fkey;
ALTER TABLE accounting.exchange_rates DROP CONSTRAINT IF EXISTS exchange_rates_created_by_fkey;
ALTER TABLE accounting.exchange_rates DROP CONSTRAINT IF EXISTS exchange_rates_updated_by_fkey;

-- Bank accounts constraint (this table is already in accounting schema)
ALTER TABLE accounting.bank_accounts DROP CONSTRAINT IF EXISTS bank_accounts_currency_id_fkey;

-- Google invoices constraints
ALTER TABLE billing.google_invoices DROP CONSTRAINT IF EXISTS google_invoices_company_id_fkey;
ALTER TABLE billing.google_invoices DROP CONSTRAINT IF EXISTS google_invoices_organization_id_fkey;
ALTER TABLE billing.google_invoices DROP CONSTRAINT IF EXISTS google_invoices_created_by_fkey;
ALTER TABLE billing.google_invoices DROP CONSTRAINT IF EXISTS google_invoices_updated_by_fkey;

-- Google invoice items constraints
ALTER TABLE billing.google_invoice_items DROP CONSTRAINT IF EXISTS google_invoice_items_google_invoice_id_fkey;
ALTER TABLE billing.google_invoice_items DROP CONSTRAINT IF EXISTS google_invoice_items_contract_product_id_fkey;
ALTER TABLE billing.google_invoice_items DROP CONSTRAINT IF EXISTS google_invoice_items_company_id_fkey;
ALTER TABLE billing.google_invoice_items DROP CONSTRAINT IF EXISTS google_invoice_items_organization_id_fkey;

-- Invoices constraints
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_google_invoice_id_fkey;
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_company_id_fkey;
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_organization_id_fkey;
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_created_by_fkey;
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_updated_by_fkey;

-- Invoice items constraints
ALTER TABLE billing.invoice_items DROP CONSTRAINT IF EXISTS invoice_items_invoice_id_fkey;
ALTER TABLE billing.invoice_items DROP CONSTRAINT IF EXISTS invoice_items_contract_product_id_fkey;
ALTER TABLE billing.invoice_items DROP CONSTRAINT IF EXISTS invoice_items_product_id_fkey;

-- Invoice payments constraint
ALTER TABLE billing.invoice_payments DROP CONSTRAINT IF EXISTS invoice_payments_payment_account_id_fkey;

-- 2. Restore invoice_items table structure
-- Add back removed columns
ALTER TABLE billing.invoice_items ADD COLUMN billing_period_start DATE;
ALTER TABLE billing.invoice_items ADD COLUMN billing_period_end DATE;
ALTER TABLE billing.invoice_items ADD COLUMN organization_id UUID;
ALTER TABLE billing.invoice_items ADD COLUMN company_id UUID;

-- Make contract_product_id and product_id NOT NULL again
ALTER TABLE billing.invoice_items ALTER COLUMN contract_product_id SET NOT NULL;
ALTER TABLE billing.invoice_items ALTER COLUMN product_id SET NOT NULL;

-- 3. Restore billing.invoices table structure
-- Remove company_id column
ALTER TABLE billing.invoices DROP COLUMN IF EXISTS company_id;

-- Rename google_invoice_id back to invoice_calculation_id
ALTER TABLE billing.invoices RENAME COLUMN google_invoice_id TO invoice_calculation_id;

-- Add back removed columns
ALTER TABLE billing.invoices ADD COLUMN billing_customer_id UUID;
ALTER TABLE billing.invoices ADD COLUMN owner_customer_id UUID;
ALTER TABLE billing.invoices ADD COLUMN supplier_id UUID;
ALTER TABLE billing.invoices ADD COLUMN payment_terms TEXT;
ALTER TABLE billing.invoices ADD COLUMN file_url VARCHAR(500);

-- 4. Rename google invoice tables back to original names
ALTER TABLE billing.google_invoice_items RENAME COLUMN google_invoice_id TO invoice_calculation_id;
ALTER TABLE billing.google_invoices RENAME TO invoice_imports;
ALTER TABLE billing.google_invoice_items RENAME TO invoice_import_items;

-- 5. Restore currencies table structure
-- Add back removed columns
ALTER TABLE accounting.currencies ADD COLUMN organization_id UUID;
ALTER TABLE accounting.currencies ADD COLUMN exchange_rate DECIMAL(10,4);

-- 6. Drop exchange_rates table
DROP TABLE IF EXISTS accounting.exchange_rates;

-- 7. Recreate original foreign key constraints
-- Currencies constraints
ALTER TABLE accounting.currencies ADD CONSTRAINT currencies_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);

-- Bank accounts constraint
ALTER TABLE accounting.bank_accounts ADD CONSTRAINT bank_accounts_currency_id_fkey 
    FOREIGN KEY (currency_id) REFERENCES accounting.currencies(id) ON DELETE RESTRICT;

-- Invoice imports constraints (restored names)
ALTER TABLE billing.invoice_imports ADD CONSTRAINT invoice_imports_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.invoice_imports ADD CONSTRAINT invoice_imports_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE billing.invoice_imports ADD CONSTRAINT invoice_imports_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE billing.invoice_imports ADD CONSTRAINT invoice_imports_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

-- Invoice import items constraints
ALTER TABLE billing.invoice_import_items ADD CONSTRAINT invoice_import_items_invoice_import_id_fkey 
    FOREIGN KEY (invoice_calculation_id) REFERENCES billing.invoice_imports(id) ON DELETE CASCADE;
ALTER TABLE billing.invoice_import_items ADD CONSTRAINT invoice_import_items_contract_product_id_fkey 
    FOREIGN KEY (contract_product_id) REFERENCES agreements.contract_products(id) ON DELETE RESTRICT;
ALTER TABLE billing.invoice_import_items ADD CONSTRAINT invoice_import_items_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.invoice_import_items ADD CONSTRAINT invoice_import_items_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);

-- Invoices constraints (restored structure)
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_invoice_calculation_id_fkey 
    FOREIGN KEY (invoice_calculation_id) REFERENCES billing.invoice_imports(id);
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_billing_customer_id_fkey 
    FOREIGN KEY (billing_customer_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_owner_customer_id_fkey 
    FOREIGN KEY (owner_customer_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_supplier_id_fkey 
    FOREIGN KEY (supplier_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

-- Invoice items constraints (restored structure)
ALTER TABLE billing.invoice_items ADD CONSTRAINT invoice_items_invoice_id_fkey 
    FOREIGN KEY (invoice_id) REFERENCES billing.invoices(id) ON DELETE CASCADE;
ALTER TABLE billing.invoice_items ADD CONSTRAINT invoice_items_contract_product_id_fkey 
    FOREIGN KEY (contract_product_id) REFERENCES agreements.contract_products(id) ON DELETE RESTRICT;
ALTER TABLE billing.invoice_items ADD CONSTRAINT invoice_items_product_id_fkey 
    FOREIGN KEY (product_id) REFERENCES catalog.products(id) ON DELETE RESTRICT;
ALTER TABLE billing.invoice_items ADD CONSTRAINT invoice_items_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.invoice_items ADD CONSTRAINT invoice_items_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);

-- Invoice payments constraint
ALTER TABLE billing.invoice_payments ADD CONSTRAINT invoice_payments_payment_account_id_fkey 
    FOREIGN KEY (payment_account_id) REFERENCES accounting.bank_accounts(id) ON DELETE RESTRICT;

COMMIT;