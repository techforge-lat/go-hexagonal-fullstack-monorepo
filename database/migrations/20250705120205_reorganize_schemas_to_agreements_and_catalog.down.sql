-- Migration: reorganize_schemas_to_agreements_and_catalog (DOWN)
-- Description: Revert schema reorganization back to original structure

BEGIN;

-- 1. Drop all foreign key constraints in agreements schema
-- Billing constraints
ALTER TABLE billing.invoice_calculation_items DROP CONSTRAINT IF EXISTS invoice_calculation_items_contract_product_id_fkey;
ALTER TABLE billing.invoice_items DROP CONSTRAINT IF EXISTS invoice_items_contract_product_id_fkey;

-- Support constraints
ALTER TABLE support.documents DROP CONSTRAINT IF EXISTS documents_contract_id_fkey;

-- Internal agreements schema constraints
ALTER TABLE agreements.contract_products DROP CONSTRAINT IF EXISTS contract_products_contract_id_fkey;
ALTER TABLE agreements.contract_products DROP CONSTRAINT IF EXISTS contract_products_product_id_fkey;
ALTER TABLE agreements.contract_products DROP CONSTRAINT IF EXISTS contract_products_product_price_id_fkey;
ALTER TABLE agreements.contract_products DROP CONSTRAINT IF EXISTS contract_products_created_by_fkey;
ALTER TABLE agreements.contract_products DROP CONSTRAINT IF EXISTS contract_products_updated_by_fkey;

ALTER TABLE agreements.contracts DROP CONSTRAINT IF EXISTS contracts_company_id_fkey;
ALTER TABLE agreements.contracts DROP CONSTRAINT IF EXISTS contracts_organization_id_fkey;
ALTER TABLE agreements.contracts DROP CONSTRAINT IF EXISTS contracts_created_by_fkey;
ALTER TABLE agreements.contracts DROP CONSTRAINT IF EXISTS contracts_updated_by_fkey;
ALTER TABLE agreements.contracts DROP CONSTRAINT IF EXISTS contracts_deleted_by_fkey;

ALTER TABLE agreements.renewal_alerts DROP CONSTRAINT IF EXISTS renewal_alerts_contract_id_fk;
ALTER TABLE agreements.renewal_alerts DROP CONSTRAINT IF EXISTS renewal_alerts_company_id_fkey;
ALTER TABLE agreements.renewal_alerts DROP CONSTRAINT IF EXISTS renewal_alerts_organization_id_fkey;
ALTER TABLE agreements.renewal_alerts DROP CONSTRAINT IF EXISTS renewal_alerts_assigned_to_fkey;
ALTER TABLE agreements.renewal_alerts DROP CONSTRAINT IF EXISTS renewal_alerts_created_by_fkey;
ALTER TABLE agreements.renewal_alerts DROP CONSTRAINT IF EXISTS renewal_alerts_updated_by_fkey;

-- 2. Rename catalog schema back to products
ALTER SCHEMA catalog RENAME TO products;

-- 3. Move tables back to original schemas
ALTER TABLE agreements.contracts SET SCHEMA products;
ALTER TABLE agreements.contract_products SET SCHEMA products;
ALTER TABLE agreements.renewal_alerts SET SCHEMA relationships;

-- 4. Drop agreements schema
DROP SCHEMA IF EXISTS agreements;

-- 5. Recreate all foreign key constraints with original schema references
-- Billing constraints referencing products
ALTER TABLE billing.invoice_calculation_items ADD CONSTRAINT invoice_calculation_items_contract_product_id_fkey 
    FOREIGN KEY (contract_product_id) REFERENCES products.contract_products(id) ON DELETE RESTRICT;
ALTER TABLE billing.invoice_items ADD CONSTRAINT invoice_items_contract_product_id_fkey 
    FOREIGN KEY (contract_product_id) REFERENCES products.contract_products(id) ON DELETE RESTRICT;

-- Support constraints referencing products
ALTER TABLE support.documents ADD CONSTRAINT documents_contract_id_fkey 
    FOREIGN KEY (contract_id) REFERENCES products.contracts(id);

-- Internal products schema constraints
ALTER TABLE products.contract_products ADD CONSTRAINT contract_products_contract_id_fkey 
    FOREIGN KEY (contract_id) REFERENCES products.contracts(id) ON DELETE CASCADE;
ALTER TABLE products.contract_products ADD CONSTRAINT contract_products_product_id_fkey 
    FOREIGN KEY (product_id) REFERENCES products.products(id) ON DELETE RESTRICT;
ALTER TABLE products.contract_products ADD CONSTRAINT contract_products_product_price_id_fkey 
    FOREIGN KEY (product_price_id) REFERENCES products.product_prices(id) ON DELETE RESTRICT;
ALTER TABLE products.contract_products ADD CONSTRAINT contract_products_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE products.contract_products ADD CONSTRAINT contract_products_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

ALTER TABLE products.contracts ADD CONSTRAINT contracts_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id) ON DELETE CASCADE;
ALTER TABLE products.contracts ADD CONSTRAINT contracts_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE products.contracts ADD CONSTRAINT contracts_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE products.contracts ADD CONSTRAINT contracts_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);
ALTER TABLE products.contracts ADD CONSTRAINT contracts_deleted_by_fkey 
    FOREIGN KEY (deleted_by) REFERENCES auth.users(id);

-- Relationships constraints
ALTER TABLE relationships.renewal_alerts ADD CONSTRAINT renewal_alerts_contract_id_fk 
    FOREIGN KEY (contract_id) REFERENCES products.contracts(id) ON DELETE CASCADE;
ALTER TABLE relationships.renewal_alerts ADD CONSTRAINT renewal_alerts_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id) ON DELETE CASCADE;
ALTER TABLE relationships.renewal_alerts ADD CONSTRAINT renewal_alerts_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE relationships.renewal_alerts ADD CONSTRAINT renewal_alerts_assigned_to_fkey 
    FOREIGN KEY (assigned_to) REFERENCES auth.users(id);
ALTER TABLE relationships.renewal_alerts ADD CONSTRAINT renewal_alerts_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE relationships.renewal_alerts ADD CONSTRAINT renewal_alerts_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

COMMIT;