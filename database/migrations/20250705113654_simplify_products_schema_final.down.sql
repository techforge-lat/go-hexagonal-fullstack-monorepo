-- Migration: simplify_products_schema_final (DOWN)
-- Description: Revert final products schema simplification

BEGIN;

-- 5. Restore setup_fee to products.contract_products table
ALTER TABLE products.contract_products ADD COLUMN setup_fee NUMERIC(10,4) DEFAULT 0;

-- 4. Restore columns to products.contracts table
ALTER TABLE products.contracts ADD COLUMN currency_code VARCHAR(3) DEFAULT 'USD';
ALTER TABLE products.contracts ADD COLUMN auto_renew BOOLEAN DEFAULT false;
ALTER TABLE products.contracts ADD COLUMN auto_renew_period VARCHAR(20);
ALTER TABLE products.contracts ADD COLUMN payment_terms VARCHAR(50);
ALTER TABLE products.contracts ADD COLUMN terms_and_conditions TEXT;

-- 3. Restore products.product_prices table structure
-- Remove config-driven columns
DROP INDEX IF EXISTS products.idx_product_prices_payment_frequency;
DROP INDEX IF EXISTS products.idx_product_prices_contract_commitment;
ALTER TABLE products.product_prices DROP CONSTRAINT IF EXISTS product_prices_payment_frequency_fkey;
ALTER TABLE products.product_prices DROP CONSTRAINT IF EXISTS product_prices_contract_commitment_fkey;
ALTER TABLE products.product_prices DROP COLUMN IF EXISTS payment_frequency;
ALTER TABLE products.product_prices DROP COLUMN IF EXISTS contract_commitment;

-- Restore old columns
ALTER TABLE products.product_prices ADD COLUMN tier_level INTEGER DEFAULT 1;
ALTER TABLE products.product_prices ADD COLUMN setup_fee NUMERIC(10,4) DEFAULT 0;
ALTER TABLE products.product_prices ADD COLUMN currency_code VARCHAR(3) DEFAULT 'USD';
ALTER TABLE products.product_prices ADD COLUMN billing_frequency VARCHAR(20);

-- 2. Restore columns to products.products table
ALTER TABLE products.products ADD COLUMN category VARCHAR(100);
ALTER TABLE products.products ADD COLUMN billing_frequency VARCHAR(20);
ALTER TABLE products.products ADD COLUMN is_recurring BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE products.products ADD COLUMN currency_code VARCHAR(3) DEFAULT 'USD';
ALTER TABLE products.products ADD COLUMN features JSONB DEFAULT '[]';
ALTER TABLE products.products ADD COLUMN specifications JSONB DEFAULT '{}';

-- 1. Remove catalog entries (optional - commented out to preserve data)
-- DELETE FROM config.catalog_options WHERE catalog_type_id IN (
--     SELECT id FROM config.catalog_types WHERE name IN ('contract_commitments', 'payment_frequencies')
-- );
-- DELETE FROM config.catalog_types WHERE name IN ('contract_commitments', 'payment_frequencies');

COMMIT;