-- Fix Organization Users for Root Access Support
-- Replace organization_customer_id with direct organization_id and customer_id
-- This allows root users to exist without being tied to specific customers

-- =============================================================================
-- 1. CREATE NEW auth.organization_users TABLE WITH PROPER STRUCTURE
-- =============================================================================

-- Create new table with correct structure
CREATE TABLE auth.organization_users_new (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES auth.organizations(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers.customers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    relationship VARCHAR(50) DEFAULT 'EMPLOYEE' NOT NULL, -- References catalog_options
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id),
    CONSTRAINT organization_users_new_org_user_customer_uk UNIQUE (organization_id, user_id, customer_id)
);

-- =============================================================================
-- 2. MIGRATE DATA FROM OLD TABLE TO NEW TABLE
-- =============================================================================

-- Migrate existing data by resolving organization_customer_id to organization_id and customer_id
INSERT INTO auth.organization_users_new (
    id, organization_id, customer_id, user_id, relationship, is_active, 
    created_at, created_by, updated_at, updated_by
)
SELECT 
    ou.id,
    oc.organization_id,
    oc.customer_id,
    ou.user_id,
    ou.relationship,
    ou.is_active,
    ou.created_at,
    ou.created_by,
    ou.updated_at,
    ou.updated_by
FROM auth.organization_users ou
JOIN auth.organization_customers oc ON oc.id = ou.organization_customer_id;

-- =============================================================================
-- 3. UPDATE auth.roles TABLE STRUCTURE
-- =============================================================================

-- Add new columns to roles table
ALTER TABLE auth.roles 
ADD COLUMN organization_id_new UUID REFERENCES auth.organizations(id) ON DELETE CASCADE,
ADD COLUMN customer_id_new UUID REFERENCES customers.customers(id) ON DELETE CASCADE;

-- Migrate data from organization_customer_id to direct organization_id/customer_id
UPDATE auth.roles 
SET 
    organization_id_new = oc.organization_id,
    customer_id_new = oc.customer_id
FROM auth.organization_customers oc 
WHERE oc.id = auth.roles.organization_customer_id;

-- Make organization_id_new NOT NULL after data migration
ALTER TABLE auth.roles 
ALTER COLUMN organization_id_new SET NOT NULL;

-- =============================================================================
-- 4. DROP OLD CONSTRAINTS AND COLUMNS
-- =============================================================================

-- Drop old constraints and indexes for organization_users
DROP INDEX IF EXISTS idx_organization_users_org_customer_id;
ALTER TABLE auth.organization_users DROP CONSTRAINT IF EXISTS organization_users_org_customer_user_uk;

-- Drop old constraint for roles
ALTER TABLE auth.roles DROP CONSTRAINT IF EXISTS roles_org_customer_code_uk;

-- =============================================================================
-- 5. REPLACE OLD TABLES AND COLUMNS
-- =============================================================================

-- Drop old organization_users table and rename new one
DROP TABLE auth.organization_users CASCADE;
ALTER TABLE auth.organization_users_new RENAME TO organization_users;

-- Replace old columns in roles table
ALTER TABLE auth.roles 
DROP COLUMN organization_customer_id;

ALTER TABLE auth.roles 
RENAME COLUMN organization_id_new TO organization_id;

ALTER TABLE auth.roles 
RENAME COLUMN customer_id_new TO customer_id;

-- =============================================================================
-- 6. CREATE NEW CONSTRAINTS AND INDEXES
-- =============================================================================

-- Create new constraint for roles
ALTER TABLE auth.roles 
ADD CONSTRAINT roles_org_customer_code_uk UNIQUE (organization_id, customer_id, code);

-- Create indexes for auth.organization_users
CREATE INDEX idx_organization_users_org_id ON auth.organization_users(organization_id);
CREATE INDEX idx_organization_users_customer_id ON auth.organization_users(customer_id);
CREATE INDEX idx_organization_users_user_id ON auth.organization_users(user_id);
CREATE INDEX idx_organization_users_relationship ON auth.organization_users(relationship);
CREATE INDEX idx_organization_users_active ON auth.organization_users(is_active);
CREATE INDEX idx_organization_users_org_customer ON auth.organization_users(organization_id, customer_id);

-- Create indexes for auth.roles new columns
CREATE INDEX idx_roles_organization_id ON auth.roles(organization_id);
CREATE INDEX idx_roles_customer_id ON auth.roles(customer_id);
CREATE INDEX idx_roles_org_customer ON auth.roles(organization_id, customer_id);

-- =============================================================================
-- 7. UPDATE EXISTING INDEXES THAT MIGHT REFERENCE OLD STRUCTURE
-- =============================================================================

-- Note: The old idx_roles_organization_customer_id will be automatically dropped
-- when we dropped the organization_customer_id column

-- =============================================================================
-- 8. EXAMPLE: CREATE ROOT ORGANIZATION USER (COMMENTED FOR SAFETY)
-- =============================================================================

-- Example of how to create a root user (uncomment and modify as needed):
-- 
-- -- First, mark an organization as root (if not already done)
-- -- UPDATE auth.organizations SET is_root_organization = true WHERE id = 'your-root-org-id';
-- 
-- -- Then create root users (users with organization but no customer)
-- -- INSERT INTO auth.organization_users (organization_id, customer_id, user_id, relationship)
-- -- VALUES ('your-root-org-id', NULL, 'your-root-user-id', 'ADMIN');

-- =============================================================================
-- 9. ADD COMMENTS FOR CLARITY
-- =============================================================================

COMMENT ON COLUMN auth.organization_users.customer_id IS 'NULL for root organization users (global access), specific customer_id for customer-scoped users';
COMMENT ON COLUMN auth.roles.customer_id IS 'NULL for organization-wide roles, specific customer_id for customer-scoped roles';