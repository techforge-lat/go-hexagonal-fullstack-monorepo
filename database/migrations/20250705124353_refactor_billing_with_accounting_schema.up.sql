-- Migration: refactor_billing_with_accounting_schema
-- Description: Create accounting schema, move financial tables, eliminate suppliers table

BEGIN;

-- 1. Migrate suppliers data to relationships.companies as SUPPLIER type
-- First, get the SUPPLIER company_type option ID
DO $$
DECLARE
    supplier_type_id UUID;
BEGIN
    SELECT co.id INTO supplier_type_id 
    FROM config.catalog_options co 
    JOIN config.catalog_types ct ON co.catalog_type_id = ct.id 
    WHERE ct.code = 'company_types' AND co.name = 'Proveedor';
    
    -- Migrate supplier data to relationships.companies
    INSERT INTO relationships.companies (
        id, business_name, tax_id, email, phone, 
        address_line_1, address_line_2, city, state_province, 
        postal_code, country, is_active, company_type,
        created_at, created_by, updated_at, updated_by
    )
    SELECT 
        s.id, s.business_name, s.tax_id, s.email, s.phone,
        s.address_line_1, s.address_line_2, s.city, s.state_province,
        s.postal_code, s.country, s.is_active, supplier_type_id,
        s.created_at, s.created_by, s.updated_at, s.updated_by
    FROM billing.suppliers s
    WHERE NOT EXISTS (
        SELECT 1 FROM relationships.companies c WHERE c.id = s.id
    );
END $$;

-- 2. Drop foreign key constraints that will be affected
-- Constraints referencing suppliers
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_supplier_id_fkey;

-- Constraints on tables being moved to accounting
ALTER TABLE billing.payment_accounts DROP CONSTRAINT IF EXISTS payment_accounts_currency_id_fkey;
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_invoice_calculation_id_fkey;
ALTER TABLE billing.invoice_calculation_items DROP CONSTRAINT IF EXISTS invoice_calculation_items_invoice_calculation_id_fkey;

-- Constraints within tables being moved
ALTER TABLE billing.currencies DROP CONSTRAINT IF EXISTS currencies_customer_id_fkey;
ALTER TABLE billing.currencies DROP CONSTRAINT IF EXISTS currencies_organization_id_fkey;

ALTER TABLE billing.invoice_calculations DROP CONSTRAINT IF EXISTS invoice_calculations_billing_customer_id_fkey;
ALTER TABLE billing.invoice_calculations DROP CONSTRAINT IF EXISTS invoice_calculations_consumer_customer_id_fkey;
ALTER TABLE billing.invoice_calculations DROP CONSTRAINT IF EXISTS invoice_calculations_organization_id_fkey;
ALTER TABLE billing.invoice_calculations DROP CONSTRAINT IF EXISTS invoice_calculations_created_by_fkey;
ALTER TABLE billing.invoice_calculations DROP CONSTRAINT IF EXISTS invoice_calculations_updated_by_fkey;

ALTER TABLE billing.invoice_calculation_items DROP CONSTRAINT IF EXISTS invoice_calculation_items_contract_product_id_fkey;
ALTER TABLE billing.invoice_calculation_items DROP CONSTRAINT IF EXISTS invoice_calculation_items_customer_id_fkey;
ALTER TABLE billing.invoice_calculation_items DROP CONSTRAINT IF EXISTS invoice_calculation_items_organization_id_fkey;

-- Constraints on suppliers table
ALTER TABLE billing.suppliers DROP CONSTRAINT IF EXISTS suppliers_customer_id_fkey;
ALTER TABLE billing.suppliers DROP CONSTRAINT IF EXISTS suppliers_organization_id_fkey;
ALTER TABLE billing.suppliers DROP CONSTRAINT IF EXISTS suppliers_created_by_fkey;
ALTER TABLE billing.suppliers DROP CONSTRAINT IF EXISTS suppliers_updated_by_fkey;

-- 3. Create accounting schema
CREATE SCHEMA IF NOT EXISTS accounting;

-- 4. Move tables to accounting schema
ALTER TABLE billing.currencies SET SCHEMA accounting;
ALTER TABLE billing.invoice_calculations SET SCHEMA accounting;
ALTER TABLE billing.invoice_calculation_items SET SCHEMA accounting;

-- 5. Remove customer_id from currencies table (make it organization-level only)
ALTER TABLE accounting.currencies DROP COLUMN IF EXISTS customer_id;

-- 6. Drop suppliers table (data already migrated to relationships.companies)
DROP TABLE IF EXISTS billing.suppliers;

-- 7. Recreate foreign key constraints with new schema references
-- Accounting schema constraints
ALTER TABLE accounting.currencies ADD CONSTRAINT currencies_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);

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

-- Billing schema constraints referencing accounting
ALTER TABLE billing.payment_accounts ADD CONSTRAINT payment_accounts_currency_id_fkey 
    FOREIGN KEY (currency_id) REFERENCES accounting.currencies(id) ON DELETE RESTRICT;
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_invoice_calculation_id_fkey 
    FOREIGN KEY (invoice_calculation_id) REFERENCES accounting.invoice_calculations(id);

-- Update invoices to reference relationships.companies instead of suppliers
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_supplier_id_fkey 
    FOREIGN KEY (supplier_id) REFERENCES relationships.companies(id);

COMMIT;