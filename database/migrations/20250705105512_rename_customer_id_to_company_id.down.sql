-- Migration: rename_customer_id_to_company_id (DOWN)
-- Description: Revert all company_id columns back to customer_id

BEGIN;

-- Note: customers.customer_users table doesn't exist - was likely handled in previous migrations

-- Support Schema
-- Revert support.document_approvals
ALTER INDEX idx_document_approvals_company_id RENAME TO idx_document_approvals_customer_id;
ALTER TABLE support.document_approvals RENAME COLUMN company_id TO customer_id;

-- Revert support.support_tickets
ALTER INDEX idx_support_tickets_company RENAME TO idx_support_tickets_customer;
ALTER TABLE support.support_tickets RENAME COLUMN company_id TO customer_id;

-- Revert support.documents
ALTER INDEX idx_documents_company RENAME TO idx_documents_customer;
ALTER TABLE support.documents RENAME COLUMN company_id TO customer_id;

-- Sales Schema
-- Revert sales.interaction_notes
ALTER INDEX idx_interaction_notes_company_id RENAME TO idx_interaction_notes_customer_id;
ALTER TABLE sales.interaction_notes RENAME COLUMN company_id TO customer_id;

-- Revert sales.proposal_items
ALTER INDEX idx_proposal_items_company_id RENAME TO idx_proposal_items_customer_id;
ALTER TABLE sales.proposal_items RENAME COLUMN company_id TO customer_id;

-- Revert sales.opportunity_products
ALTER INDEX idx_opportunity_products_company_id RENAME TO idx_opportunity_products_customer_id;
ALTER TABLE sales.opportunity_products RENAME COLUMN company_id TO customer_id;

-- Revert sales.pipeline
ALTER INDEX idx_pipeline_company_id RENAME TO idx_pipeline_customer_id;
ALTER TABLE sales.pipeline RENAME COLUMN company_id TO customer_id;

-- Revert sales.interactions
ALTER INDEX idx_interactions_company RENAME TO idx_interactions_customer;
ALTER TABLE sales.interactions RENAME COLUMN company_id TO customer_id;

-- Revert sales.proposals
ALTER TABLE sales.proposals RENAME COLUMN company_id TO customer_id;

-- Revert sales.opportunities
ALTER INDEX idx_opportunities_company RENAME TO idx_opportunities_customer;
ALTER TABLE sales.opportunities RENAME COLUMN company_id TO customer_id;

-- Billing Schema
-- Revert billing.invoice_payments
ALTER INDEX idx_invoice_payments_company_id RENAME TO idx_invoice_payments_customer_id;
ALTER TABLE billing.invoice_payments RENAME COLUMN company_id TO customer_id;

-- Revert billing.invoice_items
ALTER INDEX idx_invoice_items_company_id RENAME TO idx_invoice_items_customer_id;
ALTER TABLE billing.invoice_items RENAME COLUMN company_id TO customer_id;

-- Revert billing.invoice_calculation_items
ALTER INDEX idx_invoice_calculation_items_company_id RENAME TO idx_invoice_calculation_items_customer_id;
ALTER TABLE billing.invoice_calculation_items RENAME COLUMN company_id TO customer_id;

-- Revert billing.suppliers
ALTER INDEX idx_suppliers_company_id RENAME TO idx_suppliers_customer_id;
ALTER TABLE billing.suppliers RENAME COLUMN company_id TO customer_id;

-- Revert billing.payment_accounts
ALTER INDEX idx_payment_accounts_company_id RENAME TO idx_payment_accounts_customer_id;
ALTER TABLE billing.payment_accounts RENAME COLUMN company_id TO customer_id;

-- Revert billing.payment_methods
ALTER INDEX idx_payment_methods_company_id RENAME TO idx_payment_methods_customer_id;
ALTER TABLE billing.payment_methods RENAME COLUMN company_id TO customer_id;

-- Revert billing.currencies
ALTER INDEX idx_currencies_company_id RENAME TO idx_currencies_customer_id;
ALTER TABLE billing.currencies RENAME COLUMN company_id TO customer_id;

-- Revert billing.customer_support_services
ALTER INDEX idx_customer_support_services_company RENAME TO idx_customer_support_services_customer;
ALTER TABLE billing.customer_support_services RENAME COLUMN company_id TO customer_id;

-- Revert billing.invoices
ALTER INDEX idx_invoices_billing_company RENAME TO idx_invoices_billing_customer;
ALTER TABLE billing.invoices RENAME COLUMN owner_company_id TO owner_customer_id;
ALTER TABLE billing.invoices RENAME COLUMN billing_company_id TO billing_customer_id;

-- Revert billing.invoice_calculations
ALTER TABLE billing.invoice_calculations RENAME COLUMN consumer_company_id TO consumer_customer_id;
ALTER TABLE billing.invoice_calculations RENAME COLUMN billing_company_id TO billing_customer_id;

-- Products Schema
-- Revert products.contract_products
ALTER INDEX idx_contract_products_company_id RENAME TO idx_contract_products_customer_id;
ALTER TABLE products.contract_products RENAME COLUMN company_id TO customer_id;

-- Revert products.product_prices
ALTER INDEX idx_product_prices_company_id RENAME TO idx_product_prices_customer_id;
ALTER TABLE products.product_prices RENAME COLUMN company_id TO customer_id;

-- Revert products.products
ALTER INDEX idx_products_company_id RENAME TO idx_products_customer_id;
ALTER TABLE products.products RENAME COLUMN company_id TO customer_id;

-- Revert products.contracts
ALTER INDEX idx_contracts_billing_company RENAME TO idx_contracts_billing_customer;
ALTER INDEX idx_contracts_owner_company RENAME TO idx_contracts_owner_customer;
ALTER TABLE products.contracts RENAME COLUMN billing_company_id TO billing_customer_id;
ALTER TABLE products.contracts RENAME COLUMN owner_company_id TO owner_customer_id;

-- Auth Schema
-- Revert auth.roles
ALTER TABLE auth.roles DROP CONSTRAINT roles_org_company_code_uk;
ALTER TABLE auth.roles ADD CONSTRAINT roles_org_customer_code_uk UNIQUE (organization_id, customer_id, code);
ALTER INDEX idx_roles_org_company RENAME TO idx_roles_org_customer;
ALTER INDEX idx_roles_company_id RENAME TO idx_roles_customer_id;
ALTER TABLE auth.roles RENAME COLUMN company_id TO customer_id;

COMMIT;