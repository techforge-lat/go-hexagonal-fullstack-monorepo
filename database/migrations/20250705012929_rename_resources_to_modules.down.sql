-- Rollback Rename Resources to Modules in Auth Schema
-- Restore auth.resources and auth.resource_actions from auth.modules and auth.module_actions

-- =============================================================================
-- 1. CREATE OLD auth.resources TABLE
-- =============================================================================

CREATE TABLE auth.resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

-- =============================================================================
-- 2. CREATE OLD auth.resource_actions TABLE
-- =============================================================================

CREATE TABLE auth.resource_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID NOT NULL REFERENCES auth.resources(id) ON DELETE RESTRICT,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP,
    action_type VARCHAR(10) DEFAULT 'GET' NOT NULL,
    visibility_scope VARCHAR(20) DEFAULT 'ALL' NOT NULL,
    is_public BOOLEAN DEFAULT false NOT NULL,
    CONSTRAINT resource_actions_resource_code_uk UNIQUE (resource_id, code)
);

-- =============================================================================
-- 3. MIGRATE DATA BACK FROM NEW TABLES TO OLD TABLES
-- =============================================================================

-- Migrate data from auth.modules to auth.resources
INSERT INTO auth.resources (id, name, code, description, created_at, updated_at)
SELECT id, name, code, description, created_at, updated_at
FROM auth.modules;

-- Migrate data from auth.module_actions to auth.resource_actions
INSERT INTO auth.resource_actions (
    id, resource_id, name, code, description, created_at, updated_at,
    action_type, visibility_scope, is_public
)
SELECT 
    id, module_id, name, code, description, created_at, updated_at,
    action_type, visibility_scope, is_public
FROM auth.module_actions;

-- =============================================================================
-- 4. UPDATE auth.permissions TABLE TO USE resource_action_id
-- =============================================================================

-- Add old column for resource_action_id
ALTER TABLE auth.permissions 
ADD COLUMN resource_action_id UUID REFERENCES auth.resource_actions(id) ON DELETE CASCADE;

-- Populate resource_action_id based on existing module_action_id
UPDATE auth.permissions 
SET resource_action_id = ra.id
FROM auth.resource_actions ra
WHERE ra.id = auth.permissions.module_action_id;

-- Make resource_action_id NOT NULL after data migration
ALTER TABLE auth.permissions 
ALTER COLUMN resource_action_id SET NOT NULL;

-- Drop new module_action_id column
ALTER TABLE auth.permissions 
DROP COLUMN module_action_id;

-- =============================================================================
-- 5. DROP NEW TABLES
-- =============================================================================

DROP TABLE auth.module_actions CASCADE;
DROP TABLE auth.modules CASCADE;

-- =============================================================================
-- 6. RECREATE OLD INDEXES
-- =============================================================================

-- Indexes for auth.resources (recreated automatically with constraints)

-- Indexes for auth.resource_actions
CREATE INDEX idx_resource_actions_resource_id ON auth.resource_actions(resource_id);
CREATE INDEX idx_resource_actions_code ON auth.resource_actions(code);
CREATE INDEX idx_resource_actions_action_type ON auth.resource_actions(action_type);
CREATE INDEX idx_resource_actions_visibility_scope ON auth.resource_actions(visibility_scope);
CREATE INDEX idx_resource_actions_is_public ON auth.resource_actions(is_public);

-- Update index for auth.permissions
CREATE INDEX idx_permissions_resource_action_id ON auth.permissions(resource_action_id);

-- =============================================================================
-- 7. REMOVE COMMENTS
-- =============================================================================

COMMENT ON TABLE auth.resources IS NULL;
COMMENT ON TABLE auth.resource_actions IS NULL;
COMMENT ON COLUMN auth.resource_actions.action_type IS NULL;
COMMENT ON COLUMN auth.resource_actions.visibility_scope IS NULL;
COMMENT ON COLUMN auth.resource_actions.is_public IS NULL;