-- Rollback Schema Redesign with CRM functionality
-- This migration reverses the schema organization and removes CRM capabilities

-- =============================================================================
-- 1. DROP NEW TABLES (in reverse order due to dependencies)
-- =============================================================================

-- Support schema tables
DROP TABLE IF EXISTS support.support_tickets CASCADE;
DROP TABLE IF EXISTS support.document_approvals CASCADE;
DROP TABLE IF EXISTS support.documents CASCADE;

-- Billing enhancements
DROP TABLE IF EXISTS billing.customer_support_services CASCADE;

-- Sales schema tables
DROP TABLE IF EXISTS sales.interaction_notes CASCADE;
DROP TABLE IF EXISTS sales.interactions CASCADE;
DROP TABLE IF EXISTS sales.proposal_items CASCADE;
DROP TABLE IF EXISTS sales.proposals CASCADE;
DROP TABLE IF EXISTS sales.opportunity_products CASCADE;
DROP TABLE IF EXISTS sales.opportunities CASCADE;

-- Customer enhancements
DROP TABLE IF EXISTS customers.renewal_alerts CASCADE;
DROP TABLE IF EXISTS customers.prospects CASCADE;

-- Configuration system
DROP TABLE IF EXISTS config.catalog_options CASCADE;
DROP TABLE IF EXISTS config.catalog_types CASCADE;

-- =============================================================================
-- 2. MOVE TABLES BACK TO PUBLIC SCHEMA
-- =============================================================================

-- Move authentication tables back to public
ALTER TABLE auth.users SET SCHEMA public;
ALTER TABLE auth.resources SET SCHEMA public;
ALTER TABLE auth.resource_actions SET SCHEMA public;
ALTER TABLE auth.roles SET SCHEMA public;
ALTER TABLE auth.user_roles SET SCHEMA public;
ALTER TABLE auth.resource_role_permissions SET SCHEMA public;

-- Move customer tables back to public
ALTER TABLE customers.customers SET SCHEMA public;
ALTER TABLE customers.contacts SET SCHEMA public;
ALTER TABLE customers.customer_users SET SCHEMA public;

-- Move product tables back to public
ALTER TABLE products.products SET SCHEMA public;
ALTER TABLE products.product_prices SET SCHEMA public;
ALTER TABLE products.contracts SET SCHEMA public;
ALTER TABLE products.contract_products SET SCHEMA public;

-- Move billing tables back to public
ALTER TABLE billing.currencies SET SCHEMA public;
ALTER TABLE billing.payment_accounts SET SCHEMA public;
ALTER TABLE billing.payment_methods SET SCHEMA public;
ALTER TABLE billing.invoice_calculations SET SCHEMA public;
ALTER TABLE billing.invoice_calculation_items SET SCHEMA public;
ALTER TABLE billing.suppliers SET SCHEMA public;
ALTER TABLE billing.invoices SET SCHEMA public;
ALTER TABLE billing.invoice_items SET SCHEMA public;
ALTER TABLE billing.invoice_payments SET SCHEMA public;

-- =============================================================================
-- 3. RESTORE ORIGINAL FOREIGN KEY REFERENCES
-- =============================================================================

-- Restore original foreign key constraints (back to public schema references)
ALTER TABLE user_roles DROP CONSTRAINT user_roles_user_id_fk;
ALTER TABLE user_roles ADD CONSTRAINT user_roles_user_id_fk 
    FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE user_roles DROP CONSTRAINT user_roles_role_id_fk;
ALTER TABLE user_roles ADD CONSTRAINT user_roles_role_id_fk 
    FOREIGN KEY (role_id) REFERENCES roles(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE resource_actions DROP CONSTRAINT resource_actions_resource_id_fk;
ALTER TABLE resource_actions ADD CONSTRAINT resource_actions_resource_id_fk 
    FOREIGN KEY (resource_id) REFERENCES resources(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE resource_role_permissions DROP CONSTRAINT resource_role_permissions_resource_id_fk;
ALTER TABLE resource_role_permissions ADD CONSTRAINT resource_role_permissions_resource_id_fk 
    FOREIGN KEY (resource_id) REFERENCES resources(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE resource_role_permissions DROP CONSTRAINT resource_role_permissions_role_id_fk;
ALTER TABLE resource_role_permissions ADD CONSTRAINT resource_role_permissions_role_id_fk 
    FOREIGN KEY (role_id) REFERENCES roles(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE resource_role_permissions DROP CONSTRAINT resource_role_permissions_resource_action_id_fk;
ALTER TABLE resource_role_permissions ADD CONSTRAINT resource_role_permissions_resource_action_id_fk 
    FOREIGN KEY (resource_action_id) REFERENCES resource_actions(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE roles DROP CONSTRAINT roles_customer_id_fk;
ALTER TABLE roles ADD CONSTRAINT roles_customer_id_fk 
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE customer_users DROP CONSTRAINT customer_users_customer_id_fk;
ALTER TABLE customer_users ADD CONSTRAINT customer_users_customer_id_fk 
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE customer_users DROP CONSTRAINT customer_users_user_id_fk;
ALTER TABLE customer_users ADD CONSTRAINT customer_users_user_id_fk 
    FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE contacts DROP CONSTRAINT contacts_company_id_fk;
ALTER TABLE contacts ADD CONSTRAINT contacts_company_id_fk 
    FOREIGN KEY (company_id) REFERENCES customers(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE product_prices DROP CONSTRAINT product_prices_product_id_fk;
ALTER TABLE product_prices ADD CONSTRAINT product_prices_product_id_fk 
    FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE contracts DROP CONSTRAINT customer_product_contracts_customer_id_fk;
ALTER TABLE contracts ADD CONSTRAINT customer_product_contracts_customer_id_fk 
    FOREIGN KEY (owner_customer_id) REFERENCES customers(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE contracts DROP CONSTRAINT customer_product_contracts_billing_customer_id_fk;
ALTER TABLE contracts ADD CONSTRAINT customer_product_contracts_billing_customer_id_fk 
    FOREIGN KEY (billing_customer_id) REFERENCES customers(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE contract_products DROP CONSTRAINT contract_products_contract_id_fk;
ALTER TABLE contract_products ADD CONSTRAINT contract_products_contract_id_fk 
    FOREIGN KEY (contract_id) REFERENCES contracts(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE contract_products DROP CONSTRAINT contract_products_product_id_fk;
ALTER TABLE contract_products ADD CONSTRAINT contract_products_product_id_fk 
    FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE contract_products DROP CONSTRAINT contract_products_product_price_id;
ALTER TABLE contract_products ADD CONSTRAINT contract_products_product_price_id 
    FOREIGN KEY (product_price_id) REFERENCES product_prices(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE payment_accounts DROP CONSTRAINT payment_accounts_currency_id_fk;
ALTER TABLE payment_accounts ADD CONSTRAINT payment_accounts_currency_id_fk 
    FOREIGN KEY (currency_id) REFERENCES currencies(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE invoice_calculations DROP CONSTRAINT invoice_calculations_billing_customer_id_fk;
ALTER TABLE invoice_calculations ADD CONSTRAINT invoice_calculations_billing_customer_id_fk 
    FOREIGN KEY (billing_customer_id) REFERENCES customers(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE invoice_calculations DROP CONSTRAINT invoice_calculations_consumer_customer_id_fk;
ALTER TABLE invoice_calculations ADD CONSTRAINT invoice_calculations_consumer_customer_id_fk 
    FOREIGN KEY (consumer_customer_id) REFERENCES customers(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE invoice_calculation_items DROP CONSTRAINT invoice_calculation_items_invoice_calculation_id_fk;
ALTER TABLE invoice_calculation_items ADD CONSTRAINT invoice_calculation_items_invoice_calculation_id_fk 
    FOREIGN KEY (invoice_calculation_id) REFERENCES invoice_calculations(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE invoice_calculation_items DROP CONSTRAINT invoice_calculation_items_contract_product_id_fk;
ALTER TABLE invoice_calculation_items ADD CONSTRAINT invoice_calculation_items_contract_product_id_fk 
    FOREIGN KEY (contract_product_id) REFERENCES contract_products(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE invoices DROP CONSTRAINT invoices_billing_customer_id_fk;
ALTER TABLE invoices ADD CONSTRAINT invoices_billing_customer_id_fk 
    FOREIGN KEY (billing_customer_id) REFERENCES customers(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE invoices DROP CONSTRAINT invoices_accountable_customer_id_fk;
ALTER TABLE invoices ADD CONSTRAINT invoices_accountable_customer_id_fk 
    FOREIGN KEY (owner_customer_id) REFERENCES customers(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE invoices DROP CONSTRAINT invoices_invoice_calculation_id_fk;
ALTER TABLE invoices ADD CONSTRAINT invoices_invoice_calculation_id_fk 
    FOREIGN KEY (invoice_calculation_id) REFERENCES invoice_calculations(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE invoices DROP CONSTRAINT invoices_supplier_id_fk;
ALTER TABLE invoices ADD CONSTRAINT invoices_supplier_id_fk 
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE invoice_items DROP CONSTRAINT invoice_items_invoice_id_fk;
ALTER TABLE invoice_items ADD CONSTRAINT invoice_items_invoice_id_fk 
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE invoice_items DROP CONSTRAINT invoice_items_contract_product_id_fk;
ALTER TABLE invoice_items ADD CONSTRAINT invoice_items_contract_product_id_fk 
    FOREIGN KEY (contract_product_id) REFERENCES contract_products(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE invoice_items DROP CONSTRAINT invoice_items_product_id_fk;
ALTER TABLE invoice_items ADD CONSTRAINT invoice_items_product_id_fk 
    FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE invoice_payments DROP CONSTRAINT invoice_payments_invoice_id_fk;
ALTER TABLE invoice_payments ADD CONSTRAINT invoice_payments_invoice_id_fk 
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE invoice_payments DROP CONSTRAINT invoice_payments_payment_account_id_fk;
ALTER TABLE invoice_payments ADD CONSTRAINT invoice_payments_payment_account_id_fk 
    FOREIGN KEY (payment_account_id) REFERENCES payment_accounts(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE invoice_payments DROP CONSTRAINT invoice_payments_payment_method_id_fk;
ALTER TABLE invoice_payments ADD CONSTRAINT invoice_payments_payment_method_id_fk 
    FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

-- =============================================================================
-- 4. DROP SCHEMAS
-- =============================================================================

DROP SCHEMA IF EXISTS support CASCADE;
DROP SCHEMA IF EXISTS config CASCADE;
DROP SCHEMA IF EXISTS sales CASCADE;
DROP SCHEMA IF EXISTS billing CASCADE;
DROP SCHEMA IF EXISTS products CASCADE;
DROP SCHEMA IF EXISTS customers CASCADE;
DROP SCHEMA IF EXISTS auth CASCADE;