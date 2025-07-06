-- Migration: refactor_billing_schema_final_cleanup
-- Description: Final billing schema cleanup with exchange rates table, Google invoices renaming, and invoices table restructuring

BEGIN;

-- 1. Drop foreign key constraints that will be affected
-- Bank accounts constraints (was moved from billing.payment_accounts to accounting.bank_accounts)
ALTER TABLE accounting.bank_accounts DROP CONSTRAINT IF EXISTS bank_accounts_currency_id_fkey;

-- Invoice payments constraints (references accounting.bank_accounts)
ALTER TABLE billing.invoice_payments DROP CONSTRAINT IF EXISTS invoice_payments_payment_account_id_fkey;
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_invoice_calculation_id_fkey;
ALTER TABLE billing.invoice_import_items DROP CONSTRAINT IF EXISTS invoice_import_items_invoice_import_id_fkey;

-- Invoices constraints
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_supplier_id_fkey;
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_billing_customer_id_fkey;
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_owner_customer_id_fkey;
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_organization_id_fkey;
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_created_by_fkey;
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_updated_by_fkey;

-- Invoice items constraints
ALTER TABLE billing.invoice_items DROP CONSTRAINT IF EXISTS invoice_items_invoice_id_fkey;
ALTER TABLE billing.invoice_items DROP CONSTRAINT IF EXISTS invoice_items_contract_product_id_fkey;
ALTER TABLE billing.invoice_items DROP CONSTRAINT IF EXISTS invoice_items_product_id_fkey;
ALTER TABLE billing.invoice_items DROP CONSTRAINT IF EXISTS invoice_items_company_id_fkey;
ALTER TABLE billing.invoice_items DROP CONSTRAINT IF EXISTS invoice_items_organization_id_fkey;

-- Google invoice items constraints
ALTER TABLE billing.invoice_import_items DROP CONSTRAINT IF EXISTS invoice_import_items_contract_product_id_fkey;
ALTER TABLE billing.invoice_import_items DROP CONSTRAINT IF EXISTS invoice_import_items_company_id_fkey;
ALTER TABLE billing.invoice_import_items DROP CONSTRAINT IF EXISTS invoice_import_items_organization_id_fkey;

-- 2. Create new exchange_rates table to maintain history
CREATE TABLE accounting.exchange_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_currency_id UUID NOT NULL,
    to_currency_id UUID NOT NULL,
    rate DECIMAL(15,6) NOT NULL,
    effective_date DATE NOT NULL,
    source VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    created_by UUID,
    updated_by UUID
);

-- Create indexes for exchange_rates table
CREATE INDEX idx_exchange_rates_from_currency ON accounting.exchange_rates(from_currency_id);
CREATE INDEX idx_exchange_rates_to_currency ON accounting.exchange_rates(to_currency_id);
CREATE INDEX idx_exchange_rates_effective_date ON accounting.exchange_rates(effective_date);
CREATE INDEX idx_exchange_rates_active ON accounting.exchange_rates(is_active);
CREATE UNIQUE INDEX idx_exchange_rates_unique_rate ON accounting.exchange_rates(from_currency_id, to_currency_id, effective_date);

-- 3. Remove organization_id and exchange_rate columns from currencies table
ALTER TABLE accounting.currencies DROP COLUMN IF EXISTS organization_id;
ALTER TABLE accounting.currencies DROP COLUMN IF EXISTS exchange_rate;

-- 4. Rename invoice import tables to google invoice tables
ALTER TABLE billing.invoice_imports RENAME TO google_invoices;
ALTER TABLE billing.invoice_import_items RENAME TO google_invoice_items;

-- 5. Update invoice_payments to reference new table names
-- The payment_account_id already points to accounting.bank_accounts, so no change needed there

-- 6. Restructure billing.invoices table
-- Remove unwanted columns
ALTER TABLE billing.invoices DROP COLUMN IF EXISTS billing_customer_id;
ALTER TABLE billing.invoices DROP COLUMN IF EXISTS owner_customer_id;
ALTER TABLE billing.invoices DROP COLUMN IF EXISTS supplier_id;
ALTER TABLE billing.invoices DROP COLUMN IF EXISTS payment_terms;
ALTER TABLE billing.invoices DROP COLUMN IF EXISTS file_url;

-- Rename invoice_calculation_id to google_invoice_id
ALTER TABLE billing.invoices RENAME COLUMN invoice_calculation_id TO google_invoice_id;

-- Add company_id column
ALTER TABLE billing.invoices ADD COLUMN company_id UUID;

-- 7. Restructure billing.invoice_items table
-- Remove unwanted columns
ALTER TABLE billing.invoice_items DROP COLUMN IF EXISTS billing_period_start;
ALTER TABLE billing.invoice_items DROP COLUMN IF EXISTS billing_period_end;
ALTER TABLE billing.invoice_items DROP COLUMN IF EXISTS organization_id;
ALTER TABLE billing.invoice_items DROP COLUMN IF EXISTS company_id;

-- Make contract_product_id and product_id nullable
ALTER TABLE billing.invoice_items ALTER COLUMN contract_product_id DROP NOT NULL;
ALTER TABLE billing.invoice_items ALTER COLUMN product_id DROP NOT NULL;

-- 8. Update google_invoice_items to reference correct parent table
ALTER TABLE billing.google_invoice_items RENAME COLUMN invoice_calculation_id TO google_invoice_id;

-- 9. Recreate all foreign key constraints with correct references
-- Exchange rates constraints
ALTER TABLE accounting.exchange_rates ADD CONSTRAINT exchange_rates_from_currency_id_fkey 
    FOREIGN KEY (from_currency_id) REFERENCES accounting.currencies(id) ON DELETE RESTRICT;
ALTER TABLE accounting.exchange_rates ADD CONSTRAINT exchange_rates_to_currency_id_fkey 
    FOREIGN KEY (to_currency_id) REFERENCES accounting.currencies(id) ON DELETE RESTRICT;
ALTER TABLE accounting.exchange_rates ADD CONSTRAINT exchange_rates_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE accounting.exchange_rates ADD CONSTRAINT exchange_rates_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

-- Bank accounts constraint (currencies no longer has organization_id)
ALTER TABLE accounting.bank_accounts ADD CONSTRAINT bank_accounts_currency_id_fkey 
    FOREIGN KEY (currency_id) REFERENCES accounting.currencies(id) ON DELETE RESTRICT;

-- Google invoices constraints (renamed from invoice_imports)
ALTER TABLE billing.google_invoices ADD CONSTRAINT google_invoices_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.google_invoices ADD CONSTRAINT google_invoices_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE billing.google_invoices ADD CONSTRAINT google_invoices_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE billing.google_invoices ADD CONSTRAINT google_invoices_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

-- Google invoice items constraints (renamed from invoice_import_items)
ALTER TABLE billing.google_invoice_items ADD CONSTRAINT google_invoice_items_google_invoice_id_fkey 
    FOREIGN KEY (google_invoice_id) REFERENCES billing.google_invoices(id) ON DELETE CASCADE;
ALTER TABLE billing.google_invoice_items ADD CONSTRAINT google_invoice_items_contract_product_id_fkey 
    FOREIGN KEY (contract_product_id) REFERENCES agreements.contract_products(id) ON DELETE RESTRICT;
ALTER TABLE billing.google_invoice_items ADD CONSTRAINT google_invoice_items_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.google_invoice_items ADD CONSTRAINT google_invoice_items_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);

-- Invoices constraints (updated structure)
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_google_invoice_id_fkey 
    FOREIGN KEY (google_invoice_id) REFERENCES billing.google_invoices(id);
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

-- Invoice items constraints (simplified structure)
ALTER TABLE billing.invoice_items ADD CONSTRAINT invoice_items_invoice_id_fkey 
    FOREIGN KEY (invoice_id) REFERENCES billing.invoices(id) ON DELETE CASCADE;
ALTER TABLE billing.invoice_items ADD CONSTRAINT invoice_items_contract_product_id_fkey 
    FOREIGN KEY (contract_product_id) REFERENCES agreements.contract_products(id) ON DELETE RESTRICT;
ALTER TABLE billing.invoice_items ADD CONSTRAINT invoice_items_product_id_fkey 
    FOREIGN KEY (product_id) REFERENCES catalog.products(id) ON DELETE RESTRICT;

-- Invoice payments constraint (reference to bank accounts)
ALTER TABLE billing.invoice_payments ADD CONSTRAINT invoice_payments_payment_account_id_fkey 
    FOREIGN KEY (payment_account_id) REFERENCES accounting.bank_accounts(id) ON DELETE RESTRICT;

COMMIT;