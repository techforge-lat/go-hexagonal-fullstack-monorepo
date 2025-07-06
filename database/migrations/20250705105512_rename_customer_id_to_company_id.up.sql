-- Migration: rename_customer_id_to_company_id
-- Description: Rename all customer_id columns throughout the system to company_id for consistency

BEGIN;

-- Auth Schema - Use schema-qualified names
ALTER INDEX auth.idx_roles_customer_id RENAME TO idx_roles_company_id;
ALTER INDEX auth.idx_roles_org_customer RENAME TO idx_roles_org_company;

-- Drop and recreate constraint
ALTER TABLE auth.roles DROP CONSTRAINT IF EXISTS roles_org_customer_code_uk;

-- Rename column
ALTER TABLE auth.roles RENAME COLUMN customer_id TO company_id;

-- Add new constraint
ALTER TABLE auth.roles ADD CONSTRAINT roles_org_company_code_uk UNIQUE (organization_id, company_id, code);

COMMIT;