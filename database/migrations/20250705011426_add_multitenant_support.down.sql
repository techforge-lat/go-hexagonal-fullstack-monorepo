-- Rollback Multitenant Support from Database Schema
-- Remove organization_id and customer_id columns from all business tables

-- =============================================================================
-- 1. DROP INDEXES
-- =============================================================================

-- Support schema indexes
DROP INDEX IF EXISTS idx_support_tickets_organization_id;
DROP INDEX IF EXISTS idx_document_approvals_org_customer;
DROP INDEX IF EXISTS idx_document_approvals_customer_id;
DROP INDEX IF EXISTS idx_document_approvals_organization_id;
DROP INDEX IF EXISTS idx_documents_organization_id;

-- Sales schema indexes
DROP INDEX IF EXISTS idx_interaction_notes_org_customer;
DROP INDEX IF EXISTS idx_interaction_notes_customer_id;
DROP INDEX IF EXISTS idx_interaction_notes_organization_id;
DROP INDEX IF EXISTS idx_interactions_organization_id;
DROP INDEX IF EXISTS idx_proposal_items_org_customer;
DROP INDEX IF EXISTS idx_proposal_items_customer_id;
DROP INDEX IF EXISTS idx_proposal_items_organization_id;
DROP INDEX IF EXISTS idx_proposals_organization_id;
DROP INDEX IF EXISTS idx_opportunity_products_org_customer;
DROP INDEX IF EXISTS idx_opportunity_products_customer_id;
DROP INDEX IF EXISTS idx_opportunity_products_organization_id;
DROP INDEX IF EXISTS idx_opportunities_organization_id;

-- Billing schema indexes
DROP INDEX IF EXISTS idx_customer_support_services_organization_id;
DROP INDEX IF EXISTS idx_invoice_payments_org_customer;
DROP INDEX IF EXISTS idx_invoice_payments_customer_id;
DROP INDEX IF EXISTS idx_invoice_payments_organization_id;
DROP INDEX IF EXISTS idx_invoice_items_org_customer;
DROP INDEX IF EXISTS idx_invoice_items_customer_id;
DROP INDEX IF EXISTS idx_invoice_items_organization_id;
DROP INDEX IF EXISTS idx_invoices_organization_id;
DROP INDEX IF EXISTS idx_invoice_calculation_items_org_customer;
DROP INDEX IF EXISTS idx_invoice_calculation_items_customer_id;
DROP INDEX IF EXISTS idx_invoice_calculation_items_organization_id;
DROP INDEX IF EXISTS idx_invoice_calculations_organization_id;
DROP INDEX IF EXISTS idx_suppliers_org_customer;
DROP INDEX IF EXISTS idx_suppliers_customer_id;
DROP INDEX IF EXISTS idx_suppliers_organization_id;
DROP INDEX IF EXISTS idx_payment_accounts_org_customer;
DROP INDEX IF EXISTS idx_payment_accounts_customer_id;
DROP INDEX IF EXISTS idx_payment_accounts_organization_id;
DROP INDEX IF EXISTS idx_payment_methods_org_customer;
DROP INDEX IF EXISTS idx_payment_methods_customer_id;
DROP INDEX IF EXISTS idx_payment_methods_organization_id;
DROP INDEX IF EXISTS idx_currencies_org_customer;
DROP INDEX IF EXISTS idx_currencies_customer_id;
DROP INDEX IF EXISTS idx_currencies_organization_id;

-- Products schema indexes
DROP INDEX IF EXISTS idx_contract_products_org_customer;
DROP INDEX IF EXISTS idx_contract_products_customer_id;
DROP INDEX IF EXISTS idx_contract_products_organization_id;
DROP INDEX IF EXISTS idx_contracts_organization_id;
DROP INDEX IF EXISTS idx_product_prices_org_customer;
DROP INDEX IF EXISTS idx_product_prices_customer_id;
DROP INDEX IF EXISTS idx_product_prices_organization_id;
DROP INDEX IF EXISTS idx_products_org_customer;
DROP INDEX IF EXISTS idx_products_customer_id;
DROP INDEX IF EXISTS idx_products_organization_id;

-- Customers schema indexes
DROP INDEX IF EXISTS idx_renewal_alerts_org_customer;
DROP INDEX IF EXISTS idx_renewal_alerts_organization_id;
DROP INDEX IF EXISTS idx_contacts_org_customer;
DROP INDEX IF EXISTS idx_contacts_organization_id;
DROP INDEX IF EXISTS idx_prospects_org_customer;
DROP INDEX IF EXISTS idx_prospects_customer_id;
DROP INDEX IF EXISTS idx_prospects_organization_id;

-- Root organization indexes
DROP INDEX IF EXISTS idx_organizations_is_root;
DROP INDEX IF EXISTS idx_organizations_single_root;

-- =============================================================================
-- 2. REMOVE TENANT COLUMNS FROM SUPPORT SCHEMA
-- =============================================================================

ALTER TABLE support.support_tickets 
DROP COLUMN IF EXISTS organization_id;

ALTER TABLE support.document_approvals 
DROP COLUMN IF EXISTS organization_id,
DROP COLUMN IF EXISTS customer_id;

ALTER TABLE support.documents 
DROP COLUMN IF EXISTS organization_id;

-- =============================================================================
-- 3. REMOVE TENANT COLUMNS FROM SALES SCHEMA
-- =============================================================================

ALTER TABLE sales.interaction_notes 
DROP COLUMN IF EXISTS organization_id,
DROP COLUMN IF EXISTS customer_id;

ALTER TABLE sales.interactions 
DROP COLUMN IF EXISTS organization_id;

ALTER TABLE sales.proposal_items 
DROP COLUMN IF EXISTS organization_id,
DROP COLUMN IF EXISTS customer_id;

ALTER TABLE sales.proposals 
DROP COLUMN IF EXISTS organization_id;

ALTER TABLE sales.opportunity_products 
DROP COLUMN IF EXISTS organization_id,
DROP COLUMN IF EXISTS customer_id;

ALTER TABLE sales.opportunities 
DROP COLUMN IF EXISTS organization_id;

-- =============================================================================
-- 4. REMOVE TENANT COLUMNS FROM BILLING SCHEMA
-- =============================================================================

ALTER TABLE billing.customer_support_services 
DROP COLUMN IF EXISTS organization_id;

ALTER TABLE billing.invoice_payments 
DROP COLUMN IF EXISTS organization_id,
DROP COLUMN IF EXISTS customer_id;

ALTER TABLE billing.invoice_items 
DROP COLUMN IF EXISTS organization_id,
DROP COLUMN IF EXISTS customer_id;

ALTER TABLE billing.invoices 
DROP COLUMN IF EXISTS organization_id;

ALTER TABLE billing.invoice_calculation_items 
DROP COLUMN IF EXISTS organization_id,
DROP COLUMN IF EXISTS customer_id;

ALTER TABLE billing.invoice_calculations 
DROP COLUMN IF EXISTS organization_id;

ALTER TABLE billing.suppliers 
DROP COLUMN IF EXISTS organization_id,
DROP COLUMN IF EXISTS customer_id;

ALTER TABLE billing.payment_accounts 
DROP COLUMN IF EXISTS organization_id,
DROP COLUMN IF EXISTS customer_id;

ALTER TABLE billing.payment_methods 
DROP COLUMN IF EXISTS organization_id,
DROP COLUMN IF EXISTS customer_id;

ALTER TABLE billing.currencies 
DROP COLUMN IF EXISTS organization_id,
DROP COLUMN IF EXISTS customer_id;

-- =============================================================================
-- 5. REMOVE TENANT COLUMNS FROM PRODUCTS SCHEMA
-- =============================================================================

ALTER TABLE products.contract_products 
DROP COLUMN IF EXISTS organization_id,
DROP COLUMN IF EXISTS customer_id;

ALTER TABLE products.contracts 
DROP COLUMN IF EXISTS organization_id;

ALTER TABLE products.product_prices 
DROP COLUMN IF EXISTS organization_id,
DROP COLUMN IF EXISTS customer_id;

ALTER TABLE products.products 
DROP COLUMN IF EXISTS organization_id,
DROP COLUMN IF EXISTS customer_id;

-- =============================================================================
-- 6. REMOVE TENANT COLUMNS FROM CUSTOMERS SCHEMA
-- =============================================================================

ALTER TABLE customers.renewal_alerts 
DROP COLUMN IF EXISTS organization_id;

ALTER TABLE customers.contacts 
DROP COLUMN IF EXISTS organization_id;

ALTER TABLE customers.prospects 
DROP COLUMN IF EXISTS organization_id,
DROP COLUMN IF EXISTS customer_id;

-- =============================================================================
-- 7. REMOVE ROOT ORGANIZATION SUPPORT
-- =============================================================================

ALTER TABLE auth.organizations 
DROP COLUMN IF EXISTS is_root_organization;