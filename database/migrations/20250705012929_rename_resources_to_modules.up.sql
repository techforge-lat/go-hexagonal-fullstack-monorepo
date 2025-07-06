-- Rename Resources to Modules in Auth Schema
-- Replace auth.resources and auth.resource_actions with auth.modules and auth.module_actions

-- =============================================================================
-- 1. CREATE NEW auth.modules TABLE (RENAMED FROM auth.resources)
-- =============================================================================

CREATE TABLE auth.modules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

-- =============================================================================
-- 2. CREATE NEW auth.module_actions TABLE (RENAMED FROM auth.resource_actions)
-- =============================================================================

CREATE TABLE auth.module_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    module_id UUID NOT NULL REFERENCES auth.modules(id) ON DELETE RESTRICT,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP,
    action_type VARCHAR(10) DEFAULT 'GET' NOT NULL, -- References catalog_options
    visibility_scope VARCHAR(20) DEFAULT 'ALL' NOT NULL, -- References catalog_options
    is_public BOOLEAN DEFAULT false NOT NULL,
    CONSTRAINT module_actions_module_code_uk UNIQUE (module_id, code)
);

-- =============================================================================
-- 3. MIGRATE DATA FROM OLD TABLES TO NEW TABLES
-- =============================================================================

-- Migrate data from auth.resources to auth.modules
INSERT INTO auth.modules (id, name, code, description, created_at, updated_at)
SELECT id, name, code, description, created_at, updated_at
FROM auth.resources;

-- Migrate data from auth.resource_actions to auth.module_actions
INSERT INTO auth.module_actions (
    id, module_id, name, code, description, created_at, updated_at,
    action_type, visibility_scope, is_public
)
SELECT 
    id, resource_id, name, code, description, created_at, updated_at,
    action_type, visibility_scope, is_public
FROM auth.resource_actions;

-- =============================================================================
-- 4. UPDATE auth.permissions TABLE TO USE module_action_id
-- =============================================================================

-- Add new column for module_action_id
ALTER TABLE auth.permissions 
ADD COLUMN module_action_id UUID REFERENCES auth.module_actions(id) ON DELETE CASCADE;

-- Populate module_action_id based on existing resource_action_id
UPDATE auth.permissions 
SET module_action_id = ma.id
FROM auth.module_actions ma
WHERE ma.id = auth.permissions.resource_action_id;

-- Make module_action_id NOT NULL after data migration
ALTER TABLE auth.permissions 
ALTER COLUMN module_action_id SET NOT NULL;

-- Drop old resource_action_id column
ALTER TABLE auth.permissions 
DROP COLUMN resource_action_id;

-- =============================================================================
-- 5. DROP OLD TABLES
-- =============================================================================

DROP TABLE auth.resource_actions CASCADE;
DROP TABLE auth.resources CASCADE;

-- =============================================================================
-- 6. CREATE INDEXES FOR NEW TABLES
-- =============================================================================

-- Indexes for auth.modules
CREATE INDEX idx_modules_code ON auth.modules(code);
CREATE INDEX idx_modules_name ON auth.modules(name);

-- Indexes for auth.module_actions
CREATE INDEX idx_module_actions_module_id ON auth.module_actions(module_id);
CREATE INDEX idx_module_actions_code ON auth.module_actions(code);
CREATE INDEX idx_module_actions_action_type ON auth.module_actions(action_type);
CREATE INDEX idx_module_actions_visibility_scope ON auth.module_actions(visibility_scope);
CREATE INDEX idx_module_actions_is_public ON auth.module_actions(is_public);

-- Update index for auth.permissions
CREATE INDEX idx_permissions_module_action_id ON auth.permissions(module_action_id);

-- =============================================================================
-- 7. ADD COMMENTS FOR CLARITY
-- =============================================================================

COMMENT ON TABLE auth.modules IS 'Application modules/functionality areas for permission management';
COMMENT ON TABLE auth.module_actions IS 'Specific actions that can be performed on modules';
COMMENT ON COLUMN auth.module_actions.action_type IS 'HTTP method type: GET, POST, PUT, DELETE, PATCH, HEAD';
COMMENT ON COLUMN auth.module_actions.visibility_scope IS 'Visibility scope: ALL, INTERNAL, CUSTOMERS';
COMMENT ON COLUMN auth.module_actions.is_public IS 'If true, no permission validation is performed for this action';