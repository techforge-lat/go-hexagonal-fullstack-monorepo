-- Migration: cleanup_products_schema (DOWN)
-- Description: Revert products schema cleanup

BEGIN;

-- 5. Restore customer_id, organization_id, start_date, end_date to products.contract_products
ALTER TABLE products.contract_products ADD COLUMN customer_id UUID;
ALTER TABLE products.contract_products ADD COLUMN organization_id UUID;
ALTER TABLE products.contract_products ADD COLUMN start_date DATE;
ALTER TABLE products.contract_products ADD COLUMN end_date DATE;
ALTER TABLE products.contract_products ADD CONSTRAINT contract_products_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES customers.companies(id);
ALTER TABLE products.contract_products ADD CONSTRAINT contract_products_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
CREATE INDEX idx_contract_products_customer_id ON products.contract_products(customer_id);
CREATE INDEX idx_contract_products_organization_id ON products.contract_products(organization_id);
CREATE INDEX idx_contract_products_org_customer ON products.contract_products(organization_id, customer_id);

-- 4. Restore customer columns to products.contracts and remove company_id
DROP INDEX IF EXISTS products.idx_contracts_company_id;
ALTER TABLE products.contracts DROP CONSTRAINT IF EXISTS contracts_company_id_fkey;
ALTER TABLE products.contracts DROP COLUMN IF EXISTS company_id;

ALTER TABLE products.contracts ADD COLUMN owner_customer_id UUID;
ALTER TABLE products.contracts ADD COLUMN billing_customer_id UUID;
ALTER TABLE products.contracts ADD CONSTRAINT contracts_owner_customer_id_fkey 
    FOREIGN KEY (owner_customer_id) REFERENCES customers.companies(id);
ALTER TABLE products.contracts ADD CONSTRAINT contracts_billing_customer_id_fkey 
    FOREIGN KEY (billing_customer_id) REFERENCES customers.companies(id);
CREATE INDEX idx_contracts_owner_customer ON products.contracts(owner_customer_id);
CREATE INDEX idx_contracts_billing_customer ON products.contracts(billing_customer_id);

-- 3. Restore min_quantity and max_quantity to products.product_prices table
ALTER TABLE products.product_prices ADD COLUMN min_quantity INTEGER DEFAULT 1;
ALTER TABLE products.product_prices ADD COLUMN max_quantity INTEGER;

-- 2. Restore customer_id and organization_id to products.product_prices table
ALTER TABLE products.product_prices ADD COLUMN customer_id UUID;
ALTER TABLE products.product_prices ADD COLUMN organization_id UUID;
ALTER TABLE products.product_prices ADD CONSTRAINT product_prices_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES customers.companies(id);
ALTER TABLE products.product_prices ADD CONSTRAINT product_prices_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
CREATE INDEX idx_product_prices_customer_id ON products.product_prices(customer_id);
CREATE INDEX idx_product_prices_organization_id ON products.product_prices(organization_id);
CREATE INDEX idx_product_prices_org_customer ON products.product_prices(organization_id, customer_id);

-- 1. Restore customer_id and organization_id to products.products table
ALTER TABLE products.products ADD COLUMN customer_id UUID;
ALTER TABLE products.products ADD COLUMN organization_id UUID;
ALTER TABLE products.products ADD CONSTRAINT products_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES customers.companies(id);
ALTER TABLE products.products ADD CONSTRAINT products_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
CREATE INDEX idx_products_customer_id ON products.products(customer_id);
CREATE INDEX idx_products_organization_id ON products.products(organization_id);
CREATE INDEX idx_products_org_customer ON products.products(organization_id, customer_id);

COMMIT;