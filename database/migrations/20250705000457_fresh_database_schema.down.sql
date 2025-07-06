-- Rollback Fresh Database Schema
-- This migration removes all tables and schemas created in the fresh implementation

-- =============================================================================
-- 1. DROP TABLES (in reverse order due to dependencies)
-- =============================================================================

-- Support schema tables
DROP TABLE IF EXISTS support.support_tickets CASCADE;
DROP TABLE IF EXISTS support.document_approvals CASCADE;
DROP TABLE IF EXISTS support.documents CASCADE;

-- Sales schema tables
DROP TABLE IF EXISTS sales.interaction_notes CASCADE;
DROP TABLE IF EXISTS sales.interactions CASCADE;
DROP TABLE IF EXISTS sales.proposal_items CASCADE;
DROP TABLE IF EXISTS sales.proposals CASCADE;
DROP TABLE IF EXISTS sales.opportunity_products CASCADE;
DROP TABLE IF EXISTS sales.opportunities CASCADE;

-- Billing schema tables
DROP TABLE IF EXISTS billing.customer_support_services CASCADE;
DROP TABLE IF EXISTS billing.invoice_payments CASCADE;
DROP TABLE IF EXISTS billing.invoice_items CASCADE;
DROP TABLE IF EXISTS billing.invoices CASCADE;
DROP TABLE IF EXISTS billing.invoice_calculation_items CASCADE;
DROP TABLE IF EXISTS billing.invoice_calculations CASCADE;
DROP TABLE IF EXISTS billing.suppliers CASCADE;
DROP TABLE IF EXISTS billing.payment_accounts CASCADE;
DROP TABLE IF EXISTS billing.payment_methods CASCADE;
DROP TABLE IF EXISTS billing.currencies CASCADE;

-- Products schema tables
DROP TABLE IF EXISTS products.contract_products CASCADE;
DROP TABLE IF EXISTS products.contracts CASCADE;
DROP TABLE IF EXISTS products.product_prices CASCADE;
DROP TABLE IF EXISTS products.products CASCADE;

-- Customers schema tables
DROP TABLE IF EXISTS customers.renewal_alerts CASCADE;
DROP TABLE IF EXISTS customers.prospects CASCADE;
DROP TABLE IF EXISTS customers.customer_users CASCADE;
DROP TABLE IF EXISTS customers.contacts CASCADE;
DROP TABLE IF EXISTS customers.customers CASCADE;

-- Auth schema tables
DROP TABLE IF EXISTS auth.resource_role_permissions CASCADE;
DROP TABLE IF EXISTS auth.user_roles CASCADE;
DROP TABLE IF EXISTS auth.roles CASCADE;
DROP TABLE IF EXISTS auth.email_credentials CASCADE;
DROP TABLE IF EXISTS auth.users CASCADE;
DROP TABLE IF EXISTS auth.resource_actions CASCADE;
DROP TABLE IF EXISTS auth.resources CASCADE;

-- Configuration schema tables
DROP TABLE IF EXISTS config.catalog_options CASCADE;
DROP TABLE IF EXISTS config.catalog_types CASCADE;

-- =============================================================================
-- 2. DROP SCHEMAS
-- =============================================================================

DROP SCHEMA IF EXISTS support CASCADE;
DROP SCHEMA IF EXISTS sales CASCADE;
DROP SCHEMA IF EXISTS billing CASCADE;
DROP SCHEMA IF EXISTS products CASCADE;
DROP SCHEMA IF EXISTS customers CASCADE;
DROP SCHEMA IF EXISTS auth CASCADE;
DROP SCHEMA IF EXISTS config CASCADE;

-- =============================================================================
-- 3. DROP EXTENSIONS (optional, only if not used by other databases)
-- =============================================================================

-- DROP EXTENSION IF EXISTS "uuid-ossp";