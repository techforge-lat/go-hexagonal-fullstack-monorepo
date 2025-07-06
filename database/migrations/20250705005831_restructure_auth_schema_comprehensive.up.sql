-- Comprehensive Auth Schema Restructuring
-- Implement all requested changes to improve auth system organization

-- =============================================================================
-- 1. ADD NEW CATALOG TYPES FOR AUTH CONFIGURATIONS
-- =============================================================================

INSERT INTO config.catalog_types (name, code, description, is_active) VALUES
('Tipos de Accion HTTP', 'http_action_types', 'Tipos de acciones HTTP para endpoints', true),
('Ambitos de Visibilidad', 'visibility_scopes', 'Ambitos de visibilidad para acciones de recursos', true);

-- =============================================================================
-- 2. ADD CATALOG OPTIONS FOR NEW AUTH CONFIGURATIONS
-- =============================================================================

-- HTTP Action Types
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'http_action_types'), 'GET', 'get', 'GET', '#10B981', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'http_action_types'), 'POST', 'post', 'POST', '#3B82F6', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'http_action_types'), 'PUT', 'put', 'PUT', '#F59E0B', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'http_action_types'), 'DELETE', 'delete', 'DELETE', '#EF4444', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'http_action_types'), 'PATCH', 'patch', 'PATCH', '#8B5CF6', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'http_action_types'), 'HEAD', 'head', 'HEAD', '#6B7280', 6, true);

-- Visibility Scopes
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'visibility_scopes'), 'Todos', 'all', 'ALL', '#10B981', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'visibility_scopes'), 'Interno', 'internal', 'INTERNAL', '#EF4444', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'visibility_scopes'), 'Clientes', 'customers', 'CUSTOMERS', '#3B82F6', 3, true);

-- =============================================================================
-- 3. CREATE auth.organization_customers TABLE
-- =============================================================================

CREATE TABLE auth.organization_customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES auth.organizations(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers.customers(id) ON DELETE CASCADE,
    is_parent BOOLEAN DEFAULT false NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id),
    CONSTRAINT organization_customers_org_customer_uk UNIQUE (organization_id, customer_id)
);

-- =============================================================================
-- 4. MIGRATE DATA FROM auth.organizations TO auth.organization_customers
-- =============================================================================

-- Create organization_customers records for existing customer relationships
INSERT INTO auth.organization_customers (organization_id, customer_id, is_parent, is_active, created_at)
SELECT 
    id,
    customer_id,
    true, -- Mark as parent organization
    is_active,
    created_at
FROM auth.organizations 
WHERE customer_id IS NOT NULL;

-- =============================================================================
-- 5. ADD NEW COLUMNS TO auth.resource_actions
-- =============================================================================

ALTER TABLE auth.resource_actions 
ADD COLUMN action_type VARCHAR(10) DEFAULT 'GET' NOT NULL, -- References catalog_options
ADD COLUMN visibility_scope VARCHAR(20) DEFAULT 'ALL' NOT NULL, -- References catalog_options  
ADD COLUMN is_public BOOLEAN DEFAULT false NOT NULL;

-- =============================================================================
-- 6. CREATE NEW auth.organization_users TABLE (RENAMED FROM user_organizations)
-- =============================================================================

CREATE TABLE auth.organization_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_customer_id UUID NOT NULL REFERENCES auth.organization_customers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    relationship VARCHAR(50) DEFAULT 'EMPLOYEE' NOT NULL, -- References catalog_options
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id),
    CONSTRAINT organization_users_org_customer_user_uk UNIQUE (organization_customer_id, user_id)
);

-- =============================================================================
-- 7. MIGRATE DATA FROM auth.user_organizations TO auth.organization_users
-- =============================================================================

INSERT INTO auth.organization_users (organization_customer_id, user_id, relationship, is_active, created_at, created_by, updated_at, updated_by)
SELECT 
    oc.id,
    uo.user_id,
    uo.relationship,
    uo.is_active,
    uo.created_at,
    uo.created_by,
    uo.updated_at,
    uo.updated_by
FROM auth.user_organizations uo
JOIN auth.organization_customers oc ON oc.organization_id = uo.organization_id;

-- =============================================================================
-- 8. CREATE NEW auth.permissions TABLE (RENAMED FROM resource_role_permissions)
-- =============================================================================

CREATE TABLE auth.permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id UUID NOT NULL REFERENCES auth.roles(id) ON DELETE CASCADE,
    resource_action_id UUID NOT NULL REFERENCES auth.resource_actions(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    CONSTRAINT permissions_role_action_uk UNIQUE (role_id, resource_action_id)
);

-- =============================================================================
-- 9. MIGRATE DATA FROM auth.resource_role_permissions TO auth.permissions
-- =============================================================================

INSERT INTO auth.permissions (role_id, resource_action_id, created_at, created_by)
SELECT 
    role_id,
    resource_action_id,
    created_at,
    created_by
FROM auth.resource_role_permissions
WHERE is_granted = true; -- Only migrate granted permissions

-- =============================================================================
-- 10. UPDATE auth.roles TABLE STRUCTURE
-- =============================================================================

-- Add new column
ALTER TABLE auth.roles 
ADD COLUMN organization_customer_id UUID REFERENCES auth.organization_customers(id) ON DELETE CASCADE;

-- Migrate customer_id relationships to organization_customer_id
UPDATE auth.roles 
SET organization_customer_id = (
    SELECT oc.id 
    FROM auth.organization_customers oc 
    WHERE oc.customer_id = auth.roles.customer_id
    LIMIT 1
)
WHERE customer_id IS NOT NULL;

-- Remove old columns
ALTER TABLE auth.roles 
DROP COLUMN is_system_role,
DROP COLUMN customer_id;

-- Update constraint
ALTER TABLE auth.roles 
DROP CONSTRAINT IF EXISTS roles_customer_code_uk;

ALTER TABLE auth.roles 
ADD CONSTRAINT roles_org_customer_code_uk UNIQUE (organization_customer_id, code);

-- =============================================================================
-- 11. CLEAN UP auth.email_credentials TABLE
-- =============================================================================

ALTER TABLE auth.email_credentials 
DROP COLUMN verification_token,
DROP COLUMN verification_expires_at,
DROP COLUMN password_reset_token,
DROP COLUMN password_reset_expires_at;

-- =============================================================================
-- 12. DROP OLD TABLES
-- =============================================================================

DROP TABLE auth.user_organizations CASCADE;
DROP TABLE auth.resource_role_permissions CASCADE;

-- =============================================================================
-- 13. REMOVE customer_id FROM auth.organizations
-- =============================================================================

ALTER TABLE auth.organizations 
DROP COLUMN customer_id;

-- =============================================================================
-- 14. CREATE INDEXES FOR NEW TABLES AND COLUMNS
-- =============================================================================

-- auth.organization_customers indexes
CREATE INDEX idx_organization_customers_org_id ON auth.organization_customers(organization_id);
CREATE INDEX idx_organization_customers_customer_id ON auth.organization_customers(customer_id);
CREATE INDEX idx_organization_customers_is_parent ON auth.organization_customers(is_parent);
CREATE INDEX idx_organization_customers_active ON auth.organization_customers(is_active);

-- auth.organization_users indexes  
CREATE INDEX idx_organization_users_org_customer_id ON auth.organization_users(organization_customer_id);
CREATE INDEX idx_organization_users_user_id ON auth.organization_users(user_id);
CREATE INDEX idx_organization_users_relationship ON auth.organization_users(relationship);
CREATE INDEX idx_organization_users_active ON auth.organization_users(is_active);

-- auth.permissions indexes
CREATE INDEX idx_permissions_role_id ON auth.permissions(role_id);
CREATE INDEX idx_permissions_resource_action_id ON auth.permissions(resource_action_id);

-- auth.resource_actions new column indexes
CREATE INDEX idx_resource_actions_action_type ON auth.resource_actions(action_type);
CREATE INDEX idx_resource_actions_visibility_scope ON auth.resource_actions(visibility_scope);
CREATE INDEX idx_resource_actions_is_public ON auth.resource_actions(is_public);

-- auth.roles new column indexes
CREATE INDEX idx_roles_organization_customer_id ON auth.roles(organization_customer_id);