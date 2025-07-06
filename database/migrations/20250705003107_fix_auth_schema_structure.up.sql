-- Fix Auth Schema Structure
-- Move customer_users to auth schema and create organizations table
-- Replace enum values with config schema references

-- =============================================================================
-- 1. ADD NEW CATALOG TYPES FOR AUTH-RELATED CONFIGURATIONS
-- =============================================================================

INSERT INTO config.catalog_types (name, code, description, is_active) VALUES
('Tipos de Relacion Usuario-Cliente', 'user_customer_relationships', 'Tipos de relacion entre usuarios y clientes/organizaciones', true),
('Tipos de Organizacion', 'organization_types', 'Tipos de organizaciones en el sistema', true),
('Estados de Organizacion', 'organization_statuses', 'Estados de las organizaciones', true);

-- =============================================================================
-- 2. ADD CATALOG OPTIONS FOR AUTH CONFIGURATIONS
-- =============================================================================

-- User-Customer Relationship Types
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'user_customer_relationships'), 'Empleado', 'employee', 'EMPLOYEE', '#3B82F6', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'user_customer_relationships'), 'Administrador', 'admin', 'ADMIN', '#EF4444', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'user_customer_relationships'), 'Contacto', 'contact', 'CONTACT', '#10B981', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'user_customer_relationships'), 'Propietario', 'owner', 'OWNER', '#8B5CF6', 4, true);

-- Organization Types
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'organization_types'), 'Cliente', 'customer', 'CUSTOMER', '#10B981', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'organization_types'), 'Proveedor', 'supplier', 'SUPPLIER', '#3B82F6', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'organization_types'), 'Socio', 'partner', 'PARTNER', '#F59E0B', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'organization_types'), 'Interno', 'internal', 'INTERNAL', '#8B5CF6', 4, true);

-- Organization Statuses
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'organization_statuses'), 'Activo', 'active', 'ACTIVE', '#10B981', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'organization_statuses'), 'Inactivo', 'inactive', 'INACTIVE', '#6B7280', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'organization_statuses'), 'Suspendido', 'suspended', 'SUSPENDED', '#EF4444', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'organization_statuses'), 'Pendiente', 'pending', 'PENDING', '#F59E0B', 4, true);

-- =============================================================================
-- 3. CREATE ORGANIZATIONS TABLE IN AUTH SCHEMA
-- =============================================================================

CREATE TABLE auth.organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    code VARCHAR(100) UNIQUE,
    description TEXT,
    customer_id UUID REFERENCES customers.customers(id) ON DELETE SET NULL,
    organization_type VARCHAR(50) DEFAULT 'CUSTOMER' NOT NULL, -- References catalog_options
    status VARCHAR(50) DEFAULT 'ACTIVE' NOT NULL, -- References catalog_options
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id),
    deleted_at TIMESTAMP,
    deleted_by UUID REFERENCES auth.users(id)
);

-- =============================================================================
-- 4. CREATE NEW USER_ORGANIZATIONS TABLE IN AUTH SCHEMA
-- =============================================================================

CREATE TABLE auth.user_organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES auth.organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    relationship VARCHAR(50) DEFAULT 'EMPLOYEE' NOT NULL, -- References catalog_options
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id),
    CONSTRAINT user_organizations_org_user_uk UNIQUE (organization_id, user_id)
);

-- =============================================================================
-- 5. MIGRATE DATA FROM customers.customer_users TO auth.user_organizations
-- =============================================================================

-- First, create organizations for each customer that has users
INSERT INTO auth.organizations (name, customer_id, organization_type, status, is_active, created_at)
SELECT 
    c.business_name,
    c.id,
    'CUSTOMER',
    'ACTIVE',
    c.is_active,
    NOW()
FROM customers.customers c
WHERE EXISTS (
    SELECT 1 FROM customers.customer_users cu WHERE cu.customer_id = c.id
);

-- Migrate customer_users data to user_organizations
INSERT INTO auth.user_organizations (organization_id, user_id, relationship, is_active, created_at, created_by, updated_at, updated_by)
SELECT 
    o.id,
    cu.user_id,
    cu.relationship,
    cu.is_active,
    cu.created_at,
    cu.created_by,
    cu.updated_at,
    cu.updated_by
FROM customers.customer_users cu
JOIN auth.organizations o ON o.customer_id = cu.customer_id;

-- =============================================================================
-- 6. DROP OLD TABLE AND CONSTRAINTS
-- =============================================================================

DROP TABLE customers.customer_users CASCADE;

-- =============================================================================
-- 7. CREATE INDEXES FOR NEW TABLES
-- =============================================================================

CREATE INDEX idx_organizations_customer_id ON auth.organizations(customer_id);
CREATE INDEX idx_organizations_type ON auth.organizations(organization_type);
CREATE INDEX idx_organizations_status ON auth.organizations(status);
CREATE INDEX idx_organizations_active ON auth.organizations(is_active);
CREATE INDEX idx_organizations_code ON auth.organizations(code);

CREATE INDEX idx_user_organizations_org_id ON auth.user_organizations(organization_id);
CREATE INDEX idx_user_organizations_user_id ON auth.user_organizations(user_id);
CREATE INDEX idx_user_organizations_relationship ON auth.user_organizations(relationship);
CREATE INDEX idx_user_organizations_active ON auth.user_organizations(is_active);