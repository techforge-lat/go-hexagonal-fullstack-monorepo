-- Migration: simplify_products_schema_final
-- Description: Final simplification of products schema with config schema integration

BEGIN;

-- 1. Create catalog entries for contract commitments and payment frequencies
INSERT INTO config.catalog_types (name, code, description, is_active) VALUES 
('Contract Commitments', 'contract_commitments', 'Contract commitment periods', true),
('Payment Frequencies', 'payment_frequencies', 'Payment frequency options', true)
ON CONFLICT (code) DO NOTHING;

-- Get the catalog type IDs
DO $$
DECLARE
    commitment_type_id UUID;
    frequency_type_id UUID;
BEGIN
    SELECT id INTO commitment_type_id FROM config.catalog_types WHERE code = 'contract_commitments';
    SELECT id INTO frequency_type_id FROM config.catalog_types WHERE code = 'payment_frequencies';
    
    -- Insert contract commitment options
    INSERT INTO config.catalog_options (catalog_type_id, name, code, description, sort_order, is_active) VALUES
    (commitment_type_id, '1 Month', '1_MONTH', '1 month commitment', 1, true),
    (commitment_type_id, '3 Months', '3_MONTHS', '3 months commitment', 2, true),
    (commitment_type_id, '6 Months', '6_MONTHS', '6 months commitment', 3, true),
    (commitment_type_id, '1 Year', '1_YEAR', '1 year commitment', 4, true),
    (commitment_type_id, '2 Years', '2_YEARS', '2 years commitment', 5, true),
    (commitment_type_id, '3 Years', '3_YEARS', '3 years commitment', 6, true)
    ON CONFLICT (catalog_type_id, code) DO NOTHING;
    
    -- Insert payment frequency options
    INSERT INTO config.catalog_options (catalog_type_id, name, code, description, sort_order, is_active) VALUES
    (frequency_type_id, 'Monthly', 'MONTHLY', 'Monthly payments', 1, true),
    (frequency_type_id, 'Quarterly', 'QUARTERLY', 'Quarterly payments', 2, true),
    (frequency_type_id, 'Semi-Annually', 'SEMI_ANNUALLY', 'Semi-annual payments', 3, true),
    (frequency_type_id, 'Annually', 'ANNUALLY', 'Annual payments', 4, true)
    ON CONFLICT (catalog_type_id, code) DO NOTHING;
END $$;

-- 2. Remove unnecessary columns from products.products table
ALTER TABLE products.products DROP COLUMN IF EXISTS category;
ALTER TABLE products.products DROP COLUMN IF EXISTS billing_frequency;
ALTER TABLE products.products DROP COLUMN IF EXISTS is_recurring;
ALTER TABLE products.products DROP COLUMN IF EXISTS currency_code;
ALTER TABLE products.products DROP COLUMN IF EXISTS features;
ALTER TABLE products.products DROP COLUMN IF EXISTS specifications;

-- 3. Modernize products.product_prices table
-- Remove old columns
ALTER TABLE products.product_prices DROP COLUMN IF EXISTS tier_level;
ALTER TABLE products.product_prices DROP COLUMN IF EXISTS setup_fee;
ALTER TABLE products.product_prices DROP COLUMN IF EXISTS currency_code;
ALTER TABLE products.product_prices DROP COLUMN IF EXISTS billing_frequency;

-- Add new config-driven columns
ALTER TABLE products.product_prices ADD COLUMN contract_commitment UUID;
ALTER TABLE products.product_prices ADD COLUMN payment_frequency UUID;

-- Add foreign key constraints to config schema
ALTER TABLE products.product_prices ADD CONSTRAINT product_prices_contract_commitment_fkey 
    FOREIGN KEY (contract_commitment) REFERENCES config.catalog_options(id);
ALTER TABLE products.product_prices ADD CONSTRAINT product_prices_payment_frequency_fkey 
    FOREIGN KEY (payment_frequency) REFERENCES config.catalog_options(id);

-- Add indexes for the new columns
CREATE INDEX idx_product_prices_contract_commitment ON products.product_prices(contract_commitment);
CREATE INDEX idx_product_prices_payment_frequency ON products.product_prices(payment_frequency);

-- 4. Simplify products.contracts table
ALTER TABLE products.contracts DROP COLUMN IF EXISTS currency_code;
ALTER TABLE products.contracts DROP COLUMN IF EXISTS auto_renew;
ALTER TABLE products.contracts DROP COLUMN IF EXISTS auto_renew_period;
ALTER TABLE products.contracts DROP COLUMN IF EXISTS payment_terms;
ALTER TABLE products.contracts DROP COLUMN IF EXISTS terms_and_conditions;

-- 5. Remove setup_fee from products.contract_products table
ALTER TABLE products.contract_products DROP COLUMN IF EXISTS setup_fee;

COMMIT;