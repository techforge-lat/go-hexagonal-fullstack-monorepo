-- Restrict Sales Schema to Root Organization Only
-- Remove tenant columns from sales tables since only root organization has access

-- =============================================================================
-- 1. DROP INDEXES THAT REFERENCE ORGANIZATION_ID AND CUSTOMER_ID IN INTERACTIONS
-- =============================================================================

DROP INDEX IF EXISTS idx_interactions_organization_id;
DROP INDEX IF EXISTS idx_interactions_customer_id;
DROP INDEX IF EXISTS idx_pipeline_organization_id;

-- =============================================================================
-- 2. REMOVE ORGANIZATION_ID AND CUSTOMER_ID FROM sales.interactions
-- =============================================================================

-- Remove organization_id and customer_id columns from interactions
-- Customer context will be derived through pipeline.customer_id relationship
ALTER TABLE sales.interactions 
DROP COLUMN organization_id,
DROP COLUMN customer_id;

-- =============================================================================
-- 3. REMOVE ORGANIZATION_ID FROM sales.pipeline
-- =============================================================================

-- Remove organization_id column from pipeline
-- Only root organization will have access to sales schema
ALTER TABLE sales.pipeline 
DROP COLUMN organization_id;

-- =============================================================================
-- 4. RECREATE INDEXES WITHOUT ORGANIZATION_ID
-- =============================================================================

-- No need to recreate idx_pipeline_organization_id (removed)
-- No need to recreate idx_interactions_organization_id (removed)
-- No need to recreate idx_interactions_customer_id (removed)

-- All other indexes remain as they don't reference the removed columns

-- =============================================================================
-- 5. ADD COMMENTS CLARIFYING ROOT-ORGANIZATION-ONLY ACCESS
-- =============================================================================

COMMENT ON SCHEMA sales IS 'Sales management schema - accessible only by root organization users. Customer organizations have no access to sales data.';

COMMENT ON TABLE sales.pipeline IS 'Centralized sales pipeline managed exclusively by root organization. Customer context available through customer_id column.';

COMMENT ON TABLE sales.interactions IS 'Sales communications managed by root organization. Customer context derived through pipeline.customer_id relationship.';

COMMENT ON TABLE sales.interaction_notes IS 'Detailed notes for sales interactions, managed by root organization only.';

COMMENT ON COLUMN sales.pipeline.customer_id IS 'References the customer this pipeline entry relates to. Used by root organization to track deals with specific customers.';

COMMENT ON COLUMN sales.interactions.pipeline_id IS 'Links interaction to specific pipeline entry. Customer context derived through pipeline.customer_id.';

-- =============================================================================
-- 6. SECURITY NOTE
-- =============================================================================

-- Note: Application logic must enforce that only users belonging to the root organization
-- (where auth.organizations.is_root_organization = true) can access sales schema tables.
-- This database structure removes tenant isolation since only root org has access.