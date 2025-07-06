-- Rollback Fresh Catalog Configuration Data
-- This migration removes all default catalog data

-- =============================================================================
-- 1. DELETE ALL DATA (in reverse order)
-- =============================================================================

-- Delete payment methods
DELETE FROM billing.payment_methods;

-- Delete currencies
DELETE FROM billing.currencies;

-- Delete all catalog options (will cascade due to foreign key relationships)
DELETE FROM config.catalog_options;

-- Delete all catalog types
DELETE FROM config.catalog_types;