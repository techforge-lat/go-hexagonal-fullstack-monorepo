-- Migration: reorganize_schemas_to_agreements_and_catalog
-- Description: Reorganize schemas - create agreements schema, rename products to catalog, move tables appropriately

BEGIN;

-- 1. Drop all foreign key constraints that will be affected by the reorganization
-- Billing constraints referencing contract_products
ALTER TABLE billing.invoice_calculation_items DROP CONSTRAINT IF EXISTS invoice_calculation_items_contract_product_id_fkey;
ALTER TABLE billing.invoice_items DROP CONSTRAINT IF EXISTS invoice_items_contract_product_id_fkey;

-- Support constraints referencing contracts
ALTER TABLE support.documents DROP CONSTRAINT IF EXISTS documents_contract_id_fkey;

-- Internal products schema constraints
ALTER TABLE products.contract_products DROP CONSTRAINT IF EXISTS contract_products_contract_id_fkey;
ALTER TABLE products.contract_products DROP CONSTRAINT IF EXISTS contract_products_product_id_fkey;
ALTER TABLE products.contract_products DROP CONSTRAINT IF EXISTS contract_products_product_price_id_fkey;
ALTER TABLE products.contract_products DROP CONSTRAINT IF EXISTS contract_products_created_by_fkey;
ALTER TABLE products.contract_products DROP CONSTRAINT IF EXISTS contract_products_updated_by_fkey;

ALTER TABLE products.contracts DROP CONSTRAINT IF EXISTS contracts_company_id_fkey;
ALTER TABLE products.contracts DROP CONSTRAINT IF EXISTS contracts_organization_id_fkey;
ALTER TABLE products.contracts DROP CONSTRAINT IF EXISTS contracts_created_by_fkey;
ALTER TABLE products.contracts DROP CONSTRAINT IF EXISTS contracts_updated_by_fkey;
ALTER TABLE products.contracts DROP CONSTRAINT IF EXISTS contracts_deleted_by_fkey;

-- Relationships constraints referencing contracts
ALTER TABLE relationships.renewal_alerts DROP CONSTRAINT IF EXISTS renewal_alerts_contract_id_fk;
ALTER TABLE relationships.renewal_alerts DROP CONSTRAINT IF EXISTS renewal_alerts_company_id_fkey;
ALTER TABLE relationships.renewal_alerts DROP CONSTRAINT IF EXISTS renewal_alerts_organization_id_fkey;
ALTER TABLE relationships.renewal_alerts DROP CONSTRAINT IF EXISTS renewal_alerts_assigned_to_fkey;
ALTER TABLE relationships.renewal_alerts DROP CONSTRAINT IF EXISTS renewal_alerts_created_by_fkey;
ALTER TABLE relationships.renewal_alerts DROP CONSTRAINT IF EXISTS renewal_alerts_updated_by_fkey;

-- 2. Create new agreements schema
CREATE SCHEMA IF NOT EXISTS agreements;

-- 3. Move tables to agreements schema
ALTER TABLE products.contracts SET SCHEMA agreements;
ALTER TABLE products.contract_products SET SCHEMA agreements;
ALTER TABLE relationships.renewal_alerts SET SCHEMA agreements;

-- 4. Rename products schema to catalog
ALTER SCHEMA products RENAME TO catalog;

-- 5. Recreate all foreign key constraints with new schema references
-- Billing constraints referencing agreement tables
ALTER TABLE billing.invoice_calculation_items ADD CONSTRAINT invoice_calculation_items_contract_product_id_fkey 
    FOREIGN KEY (contract_product_id) REFERENCES agreements.contract_products(id) ON DELETE RESTRICT;
ALTER TABLE billing.invoice_items ADD CONSTRAINT invoice_items_contract_product_id_fkey 
    FOREIGN KEY (contract_product_id) REFERENCES agreements.contract_products(id) ON DELETE RESTRICT;

-- Support constraints referencing agreements
ALTER TABLE support.documents ADD CONSTRAINT documents_contract_id_fkey 
    FOREIGN KEY (contract_id) REFERENCES agreements.contracts(id);

-- Internal agreements schema constraints
ALTER TABLE agreements.contract_products ADD CONSTRAINT contract_products_contract_id_fkey 
    FOREIGN KEY (contract_id) REFERENCES agreements.contracts(id) ON DELETE CASCADE;
ALTER TABLE agreements.contract_products ADD CONSTRAINT contract_products_product_id_fkey 
    FOREIGN KEY (product_id) REFERENCES catalog.products(id) ON DELETE RESTRICT;
ALTER TABLE agreements.contract_products ADD CONSTRAINT contract_products_product_price_id_fkey 
    FOREIGN KEY (product_price_id) REFERENCES catalog.product_prices(id) ON DELETE RESTRICT;
ALTER TABLE agreements.contract_products ADD CONSTRAINT contract_products_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE agreements.contract_products ADD CONSTRAINT contract_products_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

ALTER TABLE agreements.contracts ADD CONSTRAINT contracts_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id) ON DELETE CASCADE;
ALTER TABLE agreements.contracts ADD CONSTRAINT contracts_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE agreements.contracts ADD CONSTRAINT contracts_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE agreements.contracts ADD CONSTRAINT contracts_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);
ALTER TABLE agreements.contracts ADD CONSTRAINT contracts_deleted_by_fkey 
    FOREIGN KEY (deleted_by) REFERENCES auth.users(id);

ALTER TABLE agreements.renewal_alerts ADD CONSTRAINT renewal_alerts_contract_id_fk 
    FOREIGN KEY (contract_id) REFERENCES agreements.contracts(id) ON DELETE CASCADE;
ALTER TABLE agreements.renewal_alerts ADD CONSTRAINT renewal_alerts_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES relationships.companies(id) ON DELETE CASCADE;
ALTER TABLE agreements.renewal_alerts ADD CONSTRAINT renewal_alerts_organization_id_fkey 
    FOREIGN KEY (organization_id) REFERENCES auth.organizations(id);
ALTER TABLE agreements.renewal_alerts ADD CONSTRAINT renewal_alerts_assigned_to_fkey 
    FOREIGN KEY (assigned_to) REFERENCES auth.users(id);
ALTER TABLE agreements.renewal_alerts ADD CONSTRAINT renewal_alerts_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE agreements.renewal_alerts ADD CONSTRAINT renewal_alerts_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES auth.users(id);

COMMIT;