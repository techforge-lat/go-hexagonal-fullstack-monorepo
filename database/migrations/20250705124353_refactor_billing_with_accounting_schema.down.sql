-- Migration: refactor_billing_with_accounting_schema (DOWN)
-- Description: Revert accounting schema creation and billing refactoring

BEGIN;

-- 1. Drop foreign key constraints from new structure
-- Billing constraints referencing accounting
ALTER TABLE billing.payment_accounts DROP CONSTRAINT IF EXISTS payment_accounts_currency_id_fkey;
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_invoice_calculation_id_fkey;
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_supplier_id_fkey;

-- Accounting schema constraints
ALTER TABLE accounting.currencies DROP CONSTRAINT IF EXISTS currencies_organization_id_fkey;

ALTER TABLE accounting.invoice_calculations DROP CONSTRAINT IF EXISTS invoice_calculations_billing_customer_id_fkey;
ALTER TABLE accounting.invoice_calculations DROP CONSTRAINT IF EXISTS invoice_calculations_consumer_customer_id_fkey;
ALTER TABLE accounting.invoice_calculations DROP CONSTRAINT IF EXISTS invoice_calculations_organization_id_fkey;
ALTER TABLE accounting.invoice_calculations DROP CONSTRAINT IF EXISTS invoice_calculations_created_by_fkey;
ALTER TABLE accounting.invoice_calculations DROP CONSTRAINT IF EXISTS invoice_calculations_updated_by_fkey;

ALTER TABLE accounting.invoice_calculation_items DROP CONSTRAINT IF EXISTS invoice_calculation_items_invoice_calculation_id_fkey;
ALTER TABLE accounting.invoice_calculation_items DROP CONSTRAINT IF EXISTS invoice_calculation_items_contract_product_id_fkey;
ALTER TABLE accounting.invoice_calculation_items DROP CONSTRAINT IF EXISTS invoice_calculation_items_customer_id_fkey;
ALTER TABLE accounting.invoice_calculation_items DROP CONSTRAINT IF EXISTS invoice_calculation_items_organization_id_fkey;

-- 2. Recreate suppliers table
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
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    created_by UUID,
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    updated_by UUID,
    organization_id UUID,
    customer_id UUID
);

-- Recreate suppliers indexes
CREATE INDEX idx_suppliers_customer_id ON billing.suppliers(customer_id);
CREATE INDEX idx_suppliers_organization_id ON billing.suppliers(organization_id);
CREATE INDEX idx_suppliers_org_customer ON billing.suppliers(organization_id, customer_id);

-- 3. Migrate supplier data back from relationships.companies
DO $$
DECLARE
    supplier_type_id UUID;
BEGIN
    SELECT co.id INTO supplier_type_id 
    FROM config.catalog_options co 
    JOIN config.catalog_types ct ON co.catalog_type_id = ct.id 
    WHERE ct.code = 'company_types' AND co.name = 'Proveedor';
    
    -- Migrate supplier data back from relationships.companies
    INSERT INTO billing.suppliers (
        id, business_name, tax_id, email, phone, 
        address_line_1, address_line_2, city, state_province, 
        postal_code, country, is_active,
        created_at, created_by, updated_at, updated_by, customer_id
    )
    SELECT 
        c.id, c.business_name, c.tax_id, c.email, c.phone,
        c.address_line_1, c.address_line_2, c.city, c.state_province,
        c.postal_code, c.country, c.is_active,
        c.created_at, c.created_by, c.updated_at, c.updated_by, c.id
    FROM relationships.companies c
    WHERE c.company_type = supplier_type_id;
    
    -- Remove supplier data from relationships.companies (they should only exist in suppliers table)
    DELETE FROM relationships.companies WHERE company_type = supplier_type_id;
END $$;

-- 4. Add customer_id back to currencies table
ALTER TABLE accounting.currencies ADD COLUMN customer_id UUID;

-- 5. Move tables back to billing schema
ALTER TABLE accounting.currencies SET SCHEMA billing;
ALTER TABLE accounting.invoice_calculations SET SCHEMA billing;
ALTER TABLE accounting.invoice_calculation_items SET SCHEMA billing;

-- 6. Drop accounting schema
DROP SCHEMA IF EXISTS accounting;

-- 7. Recreate original foreign key constraints
-- Currencies constraints
ALTER TABLE billing.currencies ADD CONSTRAINT currencies_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.currencies ADD CONSTRAINT currencies_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);

-- Invoice calculations constraints
ALTER TABLE billing.invoice_calculations ADD CONSTRAINT invoice_calculations_billing_customer_id_fkey 
    FOREIGN KEY (billing_customer_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.invoice_calculations ADD CONSTRAINT invoice_calculations_consumer_customer_id_fkey 
    FOREIGN KEY (consumer_customer_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.invoice_calculations ADD CONSTRAINT invoice_calculations_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE billing.invoice_calculations ADD CONSTRAINT invoice_calculations_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE billing.invoice_calculations ADD CONSTRAINT invoice_calculations_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

-- Invoice calculation items constraints
ALTER TABLE billing.invoice_calculation_items ADD CONSTRAINT invoice_calculation_items_invoice_calculation_id_fkey 
    FOREIGN KEY (invoice_calculation_id) REFERENCES billing.invoice_calculations(id) ON DELETE CASCADE;
ALTER TABLE billing.invoice_calculation_items ADD CONSTRAINT invoice_calculation_items_contract_product_id_fkey 
    FOREIGN KEY (contract_product_id) REFERENCES agreements.contract_products(id) ON DELETE RESTRICT;
ALTER TABLE billing.invoice_calculation_items ADD CONSTRAINT invoice_calculation_items_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.invoice_calculation_items ADD CONSTRAINT invoice_calculation_items_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);

-- Suppliers constraints
ALTER TABLE billing.suppliers ADD CONSTRAINT suppliers_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES relationships.companies(id);
ALTER TABLE billing.suppliers ADD CONSTRAINT suppliers_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE billing.suppliers ADD CONSTRAINT suppliers_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE billing.suppliers ADD CONSTRAINT suppliers_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

-- Billing constraints
ALTER TABLE billing.payment_accounts ADD CONSTRAINT payment_accounts_currency_id_fkey 
    FOREIGN KEY (currency_id) REFERENCES billing.currencies(id) ON DELETE RESTRICT;
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_invoice_calculation_id_fkey 
    FOREIGN KEY (invoice_calculation_id) REFERENCES billing.invoice_calculations(id);
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_supplier_id_fkey 
    FOREIGN KEY (supplier_id) REFERENCES billing.suppliers(id);

COMMIT;