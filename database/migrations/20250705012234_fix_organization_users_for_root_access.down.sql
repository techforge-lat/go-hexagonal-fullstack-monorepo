-- Rollback Organization Users Root Access Fix
-- Restore organization_customer_id structure

-- =============================================================================
-- 1. CREATE OLD auth.organization_users TABLE STRUCTURE
-- =============================================================================

CREATE TABLE auth.organization_users_old (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_customer_id UUID NOT NULL REFERENCES auth.organization_customers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    relationship VARCHAR(50) DEFAULT 'EMPLOYEE' NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id),
    CONSTRAINT organization_users_old_org_customer_user_uk UNIQUE (organization_customer_id, user_id)
);

-- =============================================================================
-- 2. MIGRATE DATA BACK TO OLD STRUCTURE
-- =============================================================================

-- Create organization_customers records for users that don't have them
-- (This handles the case where root users were added with customer_id = NULL)
INSERT INTO auth.organization_customers (organization_id, customer_id, is_parent, is_active, created_at)
SELECT DISTINCT 
    ou.organization_id,
    COALESCE(ou.customer_id, (SELECT id FROM customers.customers LIMIT 1)), -- Fallback to first customer if NULL
    false,
    true,
    NOW()
FROM auth.organization_users ou
WHERE NOT EXISTS (
    SELECT 1 FROM auth.organization_customers oc 
    WHERE oc.organization_id = ou.organization_id 
    AND oc.customer_id = COALESCE(ou.customer_id, (SELECT id FROM customers.customers LIMIT 1))
)
ON CONFLICT (organization_id, customer_id) DO NOTHING;

-- Migrate data back to old structure
INSERT INTO auth.organization_users_old (
    id, organization_customer_id, user_id, relationship, is_active,
    created_at, created_by, updated_at, updated_by
)
SELECT 
    ou.id,
    oc.id,
    ou.user_id,
    ou.relationship,
    ou.is_active,
    ou.created_at,
    ou.created_by,
    ou.updated_at,
    ou.updated_by
FROM auth.organization_users ou
JOIN auth.organization_customers oc ON 
    oc.organization_id = ou.organization_id 
    AND oc.customer_id = COALESCE(ou.customer_id, (SELECT id FROM customers.customers LIMIT 1));

-- =============================================================================
-- 3. RESTORE auth.roles TABLE STRUCTURE
-- =============================================================================

-- Add old column back
ALTER TABLE auth.roles 
ADD COLUMN organization_customer_id_old UUID REFERENCES auth.organization_customers(id) ON DELETE CASCADE;

-- Migrate data back to organization_customer_id
UPDATE auth.roles 
SET organization_customer_id_old = oc.id
FROM auth.organization_customers oc 
WHERE oc.organization_id = auth.roles.organization_id 
AND oc.customer_id = COALESCE(auth.roles.customer_id, (SELECT id FROM customers.customers LIMIT 1));

-- =============================================================================
-- 4. DROP NEW CONSTRAINTS AND INDEXES
-- =============================================================================

-- Drop new indexes
DROP INDEX IF EXISTS idx_organization_users_org_customer;
DROP INDEX IF EXISTS idx_organization_users_active;
DROP INDEX IF EXISTS idx_organization_users_relationship;
DROP INDEX IF EXISTS idx_organization_users_user_id;
DROP INDEX IF EXISTS idx_organization_users_customer_id;
DROP INDEX IF EXISTS idx_organization_users_org_id;

DROP INDEX IF EXISTS idx_roles_org_customer;
DROP INDEX IF EXISTS idx_roles_customer_id;
DROP INDEX IF EXISTS idx_roles_organization_id;

-- Drop new constraint
ALTER TABLE auth.roles DROP CONSTRAINT IF EXISTS roles_org_customer_code_uk;

-- =============================================================================
-- 5. REPLACE TABLES AND COLUMNS
-- =============================================================================

-- Replace organization_users table
DROP TABLE auth.organization_users CASCADE;
ALTER TABLE auth.organization_users_old RENAME TO organization_users;

-- Replace roles columns
ALTER TABLE auth.roles 
DROP COLUMN organization_id,
DROP COLUMN customer_id,
RENAME COLUMN organization_customer_id_old TO organization_customer_id;

-- =============================================================================
-- 6. RESTORE OLD CONSTRAINTS AND INDEXES
-- =============================================================================

-- Restore old constraint for roles
ALTER TABLE auth.roles 
ADD CONSTRAINT roles_org_customer_code_uk UNIQUE (organization_customer_id, code);

-- Restore old indexes for organization_users
CREATE INDEX idx_organization_users_org_customer_id ON auth.organization_users(organization_customer_id);
CREATE INDEX idx_organization_users_user_id ON auth.organization_users(user_id);
CREATE INDEX idx_organization_users_relationship ON auth.organization_users(relationship);
CREATE INDEX idx_organization_users_active ON auth.organization_users(is_active);

-- Restore old index for roles
CREATE INDEX idx_roles_organization_customer_id ON auth.roles(organization_customer_id);

-- =============================================================================
-- 7. REMOVE COMMENTS
-- =============================================================================

COMMENT ON COLUMN auth.organization_users.organization_customer_id IS NULL;
COMMENT ON COLUMN auth.roles.organization_customer_id IS NULL;