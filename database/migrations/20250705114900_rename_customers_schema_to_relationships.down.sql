-- Migration: rename_customers_schema_to_relationships (DOWN)
-- Description: Revert relationships schema back to customers and restore foreign key constraints

BEGIN;

-- 1. Drop all foreign key constraints that reference relationships schema tables
-- Auth Schema constraints
ALTER TABLE auth.organization_customers DROP CONSTRAINT IF EXISTS organization_customers_customer_id_fkey;
ALTER TABLE auth.organization_users DROP CONSTRAINT IF EXISTS organization_users_new_customer_id_fkey;
ALTER TABLE auth.roles DROP CONSTRAINT IF EXISTS roles_customer_id_new_fkey;

-- Billing Schema constraints
ALTER TABLE billing.currencies DROP CONSTRAINT IF EXISTS currencies_customer_id_fkey;
ALTER TABLE billing.customer_support_services DROP CONSTRAINT IF EXISTS customer_support_services_customer_id_fkey;
ALTER TABLE billing.invoice_calculation_items DROP CONSTRAINT IF EXISTS invoice_calculation_items_customer_id_fkey;
ALTER TABLE billing.invoice_calculations DROP CONSTRAINT IF EXISTS invoice_calculations_billing_customer_id_fkey;
ALTER TABLE billing.invoice_calculations DROP CONSTRAINT IF EXISTS invoice_calculations_consumer_customer_id_fkey;
ALTER TABLE billing.invoice_items DROP CONSTRAINT IF EXISTS invoice_items_customer_id_fkey;
ALTER TABLE billing.invoice_payments DROP CONSTRAINT IF EXISTS invoice_payments_customer_id_fkey;
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_billing_customer_id_fkey;
ALTER TABLE billing.invoices DROP CONSTRAINT IF EXISTS invoices_owner_customer_id_fkey;
ALTER TABLE billing.payment_accounts DROP CONSTRAINT IF EXISTS payment_accounts_customer_id_fkey;
ALTER TABLE billing.payment_methods DROP CONSTRAINT IF EXISTS payment_methods_customer_id_fkey;
ALTER TABLE billing.suppliers DROP CONSTRAINT IF EXISTS suppliers_customer_id_fkey;

-- Products Schema constraints
ALTER TABLE products.contracts DROP CONSTRAINT IF EXISTS contracts_company_id_fkey;

-- Sales Schema constraints
ALTER TABLE sales.interaction_notes DROP CONSTRAINT IF EXISTS interaction_notes_customer_id_fkey;
ALTER TABLE sales.pipeline DROP CONSTRAINT IF EXISTS pipeline_customer_id_fkey;

-- Support Schema constraints
ALTER TABLE support.document_approvals DROP CONSTRAINT IF EXISTS document_approvals_customer_id_fkey;
ALTER TABLE support.documents DROP CONSTRAINT IF EXISTS documents_customer_id_fkey;
ALTER TABLE support.support_tickets DROP CONSTRAINT IF EXISTS support_tickets_customer_id_fkey;

-- Internal relationships schema constraints
ALTER TABLE relationships.contacts DROP CONSTRAINT IF EXISTS contacts_company_id_fkey;
ALTER TABLE relationships.renewal_alerts DROP CONSTRAINT IF EXISTS renewal_alerts_company_id_fkey;

-- 2. Rename the schema back
ALTER SCHEMA relationships RENAME TO customers;

-- 3. Recreate all foreign key constraints with the original schema name
-- Auth Schema constraints
ALTER TABLE auth.organization_customers ADD CONSTRAINT organization_customers_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES customers.companies(id) ON DELETE CASCADE;
ALTER TABLE auth.organization_users ADD CONSTRAINT organization_users_new_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES customers.companies(id) ON DELETE CASCADE;
ALTER TABLE auth.roles ADD CONSTRAINT roles_customer_id_new_fkey 
    FOREIGN KEY (company_id) REFERENCES customers.companies(id) ON DELETE CASCADE;

-- Billing Schema constraints
ALTER TABLE billing.currencies ADD CONSTRAINT currencies_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES customers.companies(id);
ALTER TABLE billing.customer_support_services ADD CONSTRAINT customer_support_services_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES customers.companies(id);
ALTER TABLE billing.invoice_calculation_items ADD CONSTRAINT invoice_calculation_items_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES customers.companies(id);
ALTER TABLE billing.invoice_calculations ADD CONSTRAINT invoice_calculations_billing_customer_id_fkey 
    FOREIGN KEY (billing_customer_id) REFERENCES customers.companies(id);
ALTER TABLE billing.invoice_calculations ADD CONSTRAINT invoice_calculations_consumer_customer_id_fkey 
    FOREIGN KEY (consumer_customer_id) REFERENCES customers.companies(id);
ALTER TABLE billing.invoice_items ADD CONSTRAINT invoice_items_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES customers.companies(id);
ALTER TABLE billing.invoice_payments ADD CONSTRAINT invoice_payments_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES customers.companies(id);
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_billing_customer_id_fkey 
    FOREIGN KEY (billing_customer_id) REFERENCES customers.companies(id);
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_owner_customer_id_fkey 
    FOREIGN KEY (owner_customer_id) REFERENCES customers.companies(id);
ALTER TABLE billing.payment_accounts ADD CONSTRAINT payment_accounts_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES customers.companies(id);
ALTER TABLE billing.payment_methods ADD CONSTRAINT payment_methods_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES customers.companies(id);
ALTER TABLE billing.suppliers ADD CONSTRAINT suppliers_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES customers.companies(id);

-- Products Schema constraints
ALTER TABLE products.contracts ADD CONSTRAINT contracts_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES customers.companies(id) ON DELETE CASCADE;

-- Sales Schema constraints
ALTER TABLE sales.interaction_notes ADD CONSTRAINT interaction_notes_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES customers.companies(id);
ALTER TABLE sales.pipeline ADD CONSTRAINT pipeline_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES customers.companies(id);

-- Support Schema constraints
ALTER TABLE support.document_approvals ADD CONSTRAINT document_approvals_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES customers.companies(id);
ALTER TABLE support.documents ADD CONSTRAINT documents_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES customers.companies(id);
ALTER TABLE support.support_tickets ADD CONSTRAINT support_tickets_customer_id_fkey 
    FOREIGN KEY (customer_id) REFERENCES customers.companies(id);

-- Internal customers schema constraints
ALTER TABLE customers.contacts ADD CONSTRAINT contacts_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES customers.companies(id) ON DELETE CASCADE;
ALTER TABLE customers.renewal_alerts ADD CONSTRAINT renewal_alerts_company_id_fkey 
    FOREIGN KEY (company_id) REFERENCES customers.companies(id) ON DELETE CASCADE;

COMMIT;