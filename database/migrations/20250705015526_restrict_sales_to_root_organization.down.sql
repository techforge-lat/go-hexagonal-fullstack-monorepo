-- Rollback Sales Schema Root Organization Restriction
-- Restore tenant columns to sales tables

-- =============================================================================
-- 1. ADD ORGANIZATION_ID BACK TO sales.pipeline
-- =============================================================================

ALTER TABLE sales.pipeline 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id);

-- =============================================================================
-- 2. ADD ORGANIZATION_ID AND CUSTOMER_ID BACK TO sales.interactions
-- =============================================================================

ALTER TABLE sales.interactions 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id),
ADD COLUMN customer_id UUID REFERENCES customers.customers(id);

-- =============================================================================
-- 3. RECREATE INDEXES FOR TENANT COLUMNS
-- =============================================================================

CREATE INDEX idx_pipeline_organization_id ON sales.pipeline(organization_id);
CREATE INDEX idx_interactions_organization_id ON sales.interactions(organization_id);
CREATE INDEX idx_interactions_customer_id ON sales.interactions(customer_id);

-- =============================================================================
-- 4. REMOVE ROOT-ORGANIZATION-ONLY COMMENTS
-- =============================================================================

COMMENT ON SCHEMA sales IS NULL;
COMMENT ON TABLE sales.pipeline IS NULL;
COMMENT ON TABLE sales.interactions IS NULL;
COMMENT ON TABLE sales.interaction_notes IS NULL;
COMMENT ON COLUMN sales.pipeline.customer_id IS NULL;
COMMENT ON COLUMN sales.interactions.pipeline_id IS NULL;