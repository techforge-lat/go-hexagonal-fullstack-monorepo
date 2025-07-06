-- Migration: cleanup_products_schema
-- Description: Clean up products schema by removing customer_id/organization_id columns and simplifying structure

BEGIN;

-- 1. Remove customer_id and organization_id from products.products table
ALTER TABLE products.products DROP CONSTRAINT IF EXISTS products_customer_id_fkey;
ALTER TABLE products.products DROP CONSTRAINT IF EXISTS products_organization_id_fkey;
DROP INDEX IF EXISTS products.idx_products_customer_id;
DROP INDEX IF EXISTS products.idx_products_organization_id;
DROP INDEX IF EXISTS products.idx_products_org_customer;
ALTER TABLE products.products DROP COLUMN IF EXISTS customer_id;
ALTER TABLE products.products DROP COLUMN IF EXISTS organization_id;

-- 2. Remove customer_id and organization_id from products.product_prices table
ALTER TABLE products.product_prices DROP CONSTRAINT IF EXISTS product_prices_customer_id_fkey;
ALTER TABLE products.product_prices DROP CONSTRAINT IF EXISTS product_prices_organization_id_fkey;
DROP INDEX IF EXISTS products.idx_product_prices_customer_id;
DROP INDEX IF EXISTS products.idx_product_prices_organization_id;
DROP INDEX IF EXISTS products.idx_product_prices_org_customer;
ALTER TABLE products.product_prices DROP COLUMN IF EXISTS customer_id;
ALTER TABLE products.product_prices DROP COLUMN IF EXISTS organization_id;

-- 3. Remove min_quantity and max_quantity from products.product_prices table
ALTER TABLE products.product_prices DROP COLUMN IF EXISTS min_quantity;
ALTER TABLE products.product_prices DROP COLUMN IF EXISTS max_quantity;

-- 4. Modify products.contracts table - remove customer columns and add company_id
ALTER TABLE products.contracts DROP CONSTRAINT IF EXISTS contracts_owner_customer_id_fkey;
ALTER TABLE products.contracts DROP CONSTRAINT IF EXISTS contracts_billing_customer_id_fkey;
DROP INDEX IF EXISTS products.idx_contracts_owner_customer;
DROP INDEX IF EXISTS products.idx_contracts_billing_customer;
ALTER TABLE products.contracts DROP COLUMN IF EXISTS owner_customer_id;
ALTER TABLE products.contracts DROP COLUMN IF EXISTS billing_customer_id;

-- Add company_id column to products.contracts
ALTER TABLE products.contracts ADD COLUMN company_id UUID;
ALTER TABLE products.contracts ADD CONSTRAINT contracts_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES customers.companies(id) ON DELETE CASCADE;
CREATE INDEX idx_contracts_company_id ON products.contracts(company_id);

-- 5. Remove customer_id, organization_id, start_date, end_date from products.contract_products
ALTER TABLE products.contract_products DROP CONSTRAINT IF EXISTS contract_products_customer_id_fkey;
ALTER TABLE products.contract_products DROP CONSTRAINT IF EXISTS contract_products_organization_id_fkey;
DROP INDEX IF EXISTS products.idx_contract_products_customer_id;
DROP INDEX IF EXISTS products.idx_contract_products_organization_id;
DROP INDEX IF EXISTS products.idx_contract_products_org_customer;
ALTER TABLE products.contract_products DROP COLUMN IF EXISTS customer_id;
ALTER TABLE products.contract_products DROP COLUMN IF EXISTS organization_id;
ALTER TABLE products.contract_products DROP COLUMN IF EXISTS start_date;
ALTER TABLE products.contract_products DROP COLUMN IF EXISTS end_date;

COMMIT;