-- Rollback Comprehensive Auth Schema Restructuring
-- Restore previous auth schema structure

-- =============================================================================
-- 1. RECREATE OLD TABLES WITH ORIGINAL STRUCTURE
-- =============================================================================

-- Recreate auth.user_organizations table
CREATE TABLE auth.user_organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES auth.organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    relationship VARCHAR(50) DEFAULT 'EMPLOYEE' NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id),
    CONSTRAINT user_organizations_org_user_uk UNIQUE (organization_id, user_id)
);

-- Recreate auth.resource_role_permissions table
CREATE TABLE auth.resource_role_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID NOT NULL REFERENCES auth.resources(id) ON DELETE RESTRICT,
    role_id UUID NOT NULL REFERENCES auth.roles(id) ON DELETE CASCADE,
    resource_action_id UUID NOT NULL REFERENCES auth.resource_actions(id) ON DELETE CASCADE,
    is_granted BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    CONSTRAINT resource_role_permissions_uk UNIQUE (resource_id, role_id, resource_action_id)
);

-- =============================================================================
-- 2. RESTORE auth.organizations TABLE STRUCTURE
-- =============================================================================

ALTER TABLE auth.organizations 
ADD COLUMN customer_id UUID REFERENCES customers.customers(id) ON DELETE SET NULL;

-- Restore customer_id relationships
UPDATE auth.organizations 
SET customer_id = (
    SELECT oc.customer_id 
    FROM auth.organization_customers oc 
    WHERE oc.organization_id = auth.organizations.id 
    AND oc.is_parent = true
    LIMIT 1
);

-- =============================================================================
-- 3. RESTORE auth.roles TABLE STRUCTURE
-- =============================================================================

ALTER TABLE auth.roles 
ADD COLUMN is_system_role BOOLEAN DEFAULT false NOT NULL,
ADD COLUMN customer_id UUID;

-- Restore customer_id relationships
UPDATE auth.roles 
SET customer_id = (
    SELECT oc.customer_id 
    FROM auth.organization_customers oc 
    WHERE oc.id = auth.roles.organization_customer_id
)
WHERE organization_customer_id IS NOT NULL;

-- Drop new constraint and column
ALTER TABLE auth.roles 
DROP CONSTRAINT IF EXISTS roles_org_customer_code_uk,
DROP COLUMN organization_customer_id;

-- Restore old constraint
ALTER TABLE auth.roles 
ADD CONSTRAINT roles_customer_code_uk UNIQUE (customer_id, code);

-- =============================================================================
-- 4. RESTORE auth.email_credentials TABLE STRUCTURE
-- =============================================================================

ALTER TABLE auth.email_credentials 
ADD COLUMN verification_token VARCHAR(255),
ADD COLUMN verification_expires_at TIMESTAMP,
ADD COLUMN password_reset_token VARCHAR(255),
ADD COLUMN password_reset_expires_at TIMESTAMP;

-- =============================================================================
-- 5. RESTORE auth.resource_actions TABLE STRUCTURE
-- =============================================================================

ALTER TABLE auth.resource_actions 
DROP COLUMN action_type,
DROP COLUMN visibility_scope,
DROP COLUMN is_public;

-- =============================================================================
-- 6. MIGRATE DATA BACK TO OLD TABLES
-- =============================================================================

-- Migrate data back to auth.user_organizations
INSERT INTO auth.user_organizations (organization_id, user_id, relationship, is_active, created_at, created_by, updated_at, updated_by)
SELECT 
    oc.organization_id,
    ou.user_id,
    ou.relationship,
    ou.is_active,
    ou.created_at,
    ou.created_by,
    ou.updated_at,
    ou.updated_by
FROM auth.organization_users ou
JOIN auth.organization_customers oc ON oc.id = ou.organization_customer_id;

-- Migrate data back to auth.resource_role_permissions
INSERT INTO auth.resource_role_permissions (resource_id, role_id, resource_action_id, is_granted, created_at, created_by)
SELECT 
    ra.resource_id,
    p.role_id,
    p.resource_action_id,
    true,
    p.created_at,
    p.created_by
FROM auth.permissions p
JOIN auth.resource_actions ra ON ra.id = p.resource_action_id;

-- =============================================================================
-- 7. DROP NEW TABLES
-- =============================================================================

DROP TABLE auth.organization_users CASCADE;
DROP TABLE auth.permissions CASCADE;
DROP TABLE auth.organization_customers CASCADE;

-- =============================================================================
-- 8. REMOVE NEW CATALOG DATA
-- =============================================================================

DELETE FROM config.catalog_options 
WHERE catalog_type_id IN (
    SELECT id FROM config.catalog_types 
    WHERE code IN ('http_action_types', 'visibility_scopes')
);

DELETE FROM config.catalog_types 
WHERE code IN ('http_action_types', 'visibility_scopes');

-- =============================================================================
-- 9. RECREATE ORIGINAL INDEXES
-- =============================================================================

CREATE INDEX idx_user_organizations_org_id ON auth.user_organizations(organization_id);
CREATE INDEX idx_user_organizations_user_id ON auth.user_organizations(user_id);
CREATE INDEX idx_user_organizations_relationship ON auth.user_organizations(relationship);
CREATE INDEX idx_user_organizations_active ON auth.user_organizations(is_active);

CREATE INDEX idx_resource_role_permissions_resource_id ON auth.resource_role_permissions(resource_id);
CREATE INDEX idx_resource_role_permissions_role_id ON auth.resource_role_permissions(role_id);
CREATE INDEX idx_resource_role_permissions_action_id ON auth.resource_role_permissions(resource_action_id);