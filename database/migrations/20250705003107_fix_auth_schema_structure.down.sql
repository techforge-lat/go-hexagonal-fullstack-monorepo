-- Rollback Auth Schema Structure Fix
-- Restore customer_users table and remove organizations table

-- =============================================================================
-- 1. RECREATE customers.customer_users TABLE
-- =============================================================================

CREATE TABLE customers.customer_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers.customers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    relationship VARCHAR(50) DEFAULT 'EMPLOYEE' NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id),
    CONSTRAINT customer_users_customer_user_uk UNIQUE (customer_id, user_id)
);

-- =============================================================================
-- 2. MIGRATE DATA BACK FROM auth.user_organizations
-- =============================================================================

INSERT INTO customers.customer_users (customer_id, user_id, relationship, is_active, created_at, created_by, updated_at, updated_by)
SELECT 
    o.customer_id,
    uo.user_id,
    uo.relationship,
    uo.is_active,
    uo.created_at,
    uo.created_by,
    uo.updated_at,
    uo.updated_by
FROM auth.user_organizations uo
JOIN auth.organizations o ON o.id = uo.organization_id
WHERE o.customer_id IS NOT NULL;

-- =============================================================================
-- 3. DROP NEW TABLES
-- =============================================================================

DROP TABLE auth.user_organizations CASCADE;
DROP TABLE auth.organizations CASCADE;

-- =============================================================================
-- 4. REMOVE CATALOG DATA
-- =============================================================================

DELETE FROM config.catalog_options 
WHERE catalog_type_id IN (
    SELECT id FROM config.catalog_types 
    WHERE code IN ('user_customer_relationships', 'organization_types', 'organization_statuses')
);

DELETE FROM config.catalog_types 
WHERE code IN ('user_customer_relationships', 'organization_types', 'organization_statuses');

-- =============================================================================
-- 5. RECREATE INDEXES FOR customer_users
-- =============================================================================

CREATE INDEX idx_customer_users_customer_id ON customers.customer_users(customer_id);
CREATE INDEX idx_customer_users_user_id ON customers.customer_users(user_id);