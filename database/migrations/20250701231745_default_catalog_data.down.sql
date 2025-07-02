-- Rollback Default Catalog Configuration Data
-- This migration removes all default catalog data

-- =============================================================================
-- 1. DELETE ALL CATALOG OPTIONS (in reverse order)
-- =============================================================================

-- Delete all catalog options (will cascade due to foreign key relationships)
DELETE FROM config.catalog_options;

-- =============================================================================
-- 2. DELETE ALL CATALOG TYPES
-- =============================================================================

-- Delete all catalog types
DELETE FROM config.catalog_types;