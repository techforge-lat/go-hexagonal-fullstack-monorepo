-- Add Multitenant Support to Database Schema
-- Add organization_id and customer_id columns to all business tables for tenant isolation

-- =============================================================================
-- 1. ADD ROOT ORGANIZATION SUPPORT
-- =============================================================================

-- Add is_root_organization column to auth.organizations
ALTER TABLE auth.organizations 
ADD COLUMN is_root_organization BOOLEAN DEFAULT false NOT NULL;

-- Create unique constraint to ensure only one root organization
CREATE UNIQUE INDEX idx_organizations_single_root 
ON auth.organizations (is_root_organization) 
WHERE is_root_organization = true;

-- =============================================================================
-- 2. ADD TENANT COLUMNS TO CUSTOMERS SCHEMA
-- =============================================================================

-- customers.prospects
ALTER TABLE customers.prospects 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id),
ADD COLUMN customer_id UUID REFERENCES customers.customers(id);

-- customers.contacts  
ALTER TABLE customers.contacts 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id);
-- Note: customer_id already exists

-- customers.renewal_alerts
ALTER TABLE customers.renewal_alerts 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id);
-- Note: customer_id already exists

-- =============================================================================
-- 3. ADD TENANT COLUMNS TO PRODUCTS SCHEMA
-- =============================================================================

-- products.products
ALTER TABLE products.products 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id),
ADD COLUMN customer_id UUID REFERENCES customers.customers(id);

-- products.product_prices
ALTER TABLE products.product_prices 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id),
ADD COLUMN customer_id UUID REFERENCES customers.customers(id);

-- products.contracts
ALTER TABLE products.contracts 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id);
-- Note: owner_customer_id and billing_customer_id already exist

-- products.contract_products
ALTER TABLE products.contract_products 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id),
ADD COLUMN customer_id UUID REFERENCES customers.customers(id);

-- =============================================================================
-- 4. ADD TENANT COLUMNS TO BILLING SCHEMA
-- =============================================================================

-- billing.currencies
ALTER TABLE billing.currencies 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id),
ADD COLUMN customer_id UUID REFERENCES customers.customers(id);

-- billing.payment_methods
ALTER TABLE billing.payment_methods 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id),
ADD COLUMN customer_id UUID REFERENCES customers.customers(id);

-- billing.payment_accounts
ALTER TABLE billing.payment_accounts 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id),
ADD COLUMN customer_id UUID REFERENCES customers.customers(id);

-- billing.suppliers
ALTER TABLE billing.suppliers 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id),
ADD COLUMN customer_id UUID REFERENCES customers.customers(id);

-- billing.invoice_calculations
ALTER TABLE billing.invoice_calculations 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id);
-- Note: billing_customer_id and consumer_customer_id already exist

-- billing.invoice_calculation_items
ALTER TABLE billing.invoice_calculation_items 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id),
ADD COLUMN customer_id UUID REFERENCES customers.customers(id);

-- billing.invoices
ALTER TABLE billing.invoices 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id);
-- Note: billing_customer_id and owner_customer_id already exist

-- billing.invoice_items
ALTER TABLE billing.invoice_items 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id),
ADD COLUMN customer_id UUID REFERENCES customers.customers(id);

-- billing.invoice_payments
ALTER TABLE billing.invoice_payments 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id),
ADD COLUMN customer_id UUID REFERENCES customers.customers(id);

-- billing.customer_support_services
ALTER TABLE billing.customer_support_services 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id);
-- Note: customer_id already exists

-- =============================================================================
-- 5. ADD TENANT COLUMNS TO SALES SCHEMA
-- =============================================================================

-- sales.opportunities
ALTER TABLE sales.opportunities 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id);
-- Note: customer_id and prospect_id already exist

-- sales.opportunity_products
ALTER TABLE sales.opportunity_products 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id),
ADD COLUMN customer_id UUID REFERENCES customers.customers(id);

-- sales.proposals
ALTER TABLE sales.proposals 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id);
-- Note: customer_id and prospect_id already exist

-- sales.proposal_items
ALTER TABLE sales.proposal_items 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id),
ADD COLUMN customer_id UUID REFERENCES customers.customers(id);

-- sales.interactions
ALTER TABLE sales.interactions 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id);
-- Note: customer_id and prospect_id already exist

-- sales.interaction_notes
ALTER TABLE sales.interaction_notes 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id),
ADD COLUMN customer_id UUID REFERENCES customers.customers(id);

-- =============================================================================
-- 6. ADD TENANT COLUMNS TO SUPPORT SCHEMA
-- =============================================================================

-- support.documents
ALTER TABLE support.documents 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id);
-- Note: customer_id and prospect_id already exist

-- support.document_approvals
ALTER TABLE support.document_approvals 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id),
ADD COLUMN customer_id UUID REFERENCES customers.customers(id);

-- support.support_tickets
ALTER TABLE support.support_tickets 
ADD COLUMN organization_id UUID REFERENCES auth.organizations(id);
-- Note: customer_id already exists

-- =============================================================================
-- 7. POPULATE TENANT DATA BASED ON EXISTING RELATIONSHIPS
-- =============================================================================

-- Note: These are placeholder updates. In a real scenario, you would need to 
-- populate these based on your business logic and existing relationships.
-- For now, we'll leave them NULL and they can be populated via application logic.

-- Example of how you might populate organization_id for customers schema:
-- UPDATE customers.prospects SET organization_id = (
--     SELECT organization_id FROM auth.organization_customers oc 
--     WHERE oc.customer_id = customers.prospects.some_customer_reference
--     LIMIT 1
-- );

-- =============================================================================
-- 8. CREATE INDEXES FOR PERFORMANCE
-- =============================================================================

-- Customers schema indexes
CREATE INDEX idx_prospects_organization_id ON customers.prospects(organization_id);
CREATE INDEX idx_prospects_customer_id ON customers.prospects(customer_id);
CREATE INDEX idx_prospects_org_customer ON customers.prospects(organization_id, customer_id);

CREATE INDEX idx_contacts_organization_id ON customers.contacts(organization_id);
CREATE INDEX idx_contacts_org_customer ON customers.contacts(organization_id, customer_id);

CREATE INDEX idx_renewal_alerts_organization_id ON customers.renewal_alerts(organization_id);
CREATE INDEX idx_renewal_alerts_org_customer ON customers.renewal_alerts(organization_id, customer_id);

-- Products schema indexes
CREATE INDEX idx_products_organization_id ON products.products(organization_id);
CREATE INDEX idx_products_customer_id ON products.products(customer_id);
CREATE INDEX idx_products_org_customer ON products.products(organization_id, customer_id);

CREATE INDEX idx_product_prices_organization_id ON products.product_prices(organization_id);
CREATE INDEX idx_product_prices_customer_id ON products.product_prices(customer_id);
CREATE INDEX idx_product_prices_org_customer ON products.product_prices(organization_id, customer_id);

CREATE INDEX idx_contracts_organization_id ON products.contracts(organization_id);

CREATE INDEX idx_contract_products_organization_id ON products.contract_products(organization_id);
CREATE INDEX idx_contract_products_customer_id ON products.contract_products(customer_id);
CREATE INDEX idx_contract_products_org_customer ON products.contract_products(organization_id, customer_id);

-- Billing schema indexes
CREATE INDEX idx_currencies_organization_id ON billing.currencies(organization_id);
CREATE INDEX idx_currencies_customer_id ON billing.currencies(customer_id);
CREATE INDEX idx_currencies_org_customer ON billing.currencies(organization_id, customer_id);

CREATE INDEX idx_payment_methods_organization_id ON billing.payment_methods(organization_id);
CREATE INDEX idx_payment_methods_customer_id ON billing.payment_methods(customer_id);
CREATE INDEX idx_payment_methods_org_customer ON billing.payment_methods(organization_id, customer_id);

CREATE INDEX idx_payment_accounts_organization_id ON billing.payment_accounts(organization_id);
CREATE INDEX idx_payment_accounts_customer_id ON billing.payment_accounts(customer_id);
CREATE INDEX idx_payment_accounts_org_customer ON billing.payment_accounts(organization_id, customer_id);

CREATE INDEX idx_suppliers_organization_id ON billing.suppliers(organization_id);
CREATE INDEX idx_suppliers_customer_id ON billing.suppliers(customer_id);
CREATE INDEX idx_suppliers_org_customer ON billing.suppliers(organization_id, customer_id);

CREATE INDEX idx_invoice_calculations_organization_id ON billing.invoice_calculations(organization_id);

CREATE INDEX idx_invoice_calculation_items_organization_id ON billing.invoice_calculation_items(organization_id);
CREATE INDEX idx_invoice_calculation_items_customer_id ON billing.invoice_calculation_items(customer_id);
CREATE INDEX idx_invoice_calculation_items_org_customer ON billing.invoice_calculation_items(organization_id, customer_id);

CREATE INDEX idx_invoices_organization_id ON billing.invoices(organization_id);

CREATE INDEX idx_invoice_items_organization_id ON billing.invoice_items(organization_id);
CREATE INDEX idx_invoice_items_customer_id ON billing.invoice_items(customer_id);
CREATE INDEX idx_invoice_items_org_customer ON billing.invoice_items(organization_id, customer_id);

CREATE INDEX idx_invoice_payments_organization_id ON billing.invoice_payments(organization_id);
CREATE INDEX idx_invoice_payments_customer_id ON billing.invoice_payments(customer_id);
CREATE INDEX idx_invoice_payments_org_customer ON billing.invoice_payments(organization_id, customer_id);

CREATE INDEX idx_customer_support_services_organization_id ON billing.customer_support_services(organization_id);

-- Sales schema indexes
CREATE INDEX idx_opportunities_organization_id ON sales.opportunities(organization_id);

CREATE INDEX idx_opportunity_products_organization_id ON sales.opportunity_products(organization_id);
CREATE INDEX idx_opportunity_products_customer_id ON sales.opportunity_products(customer_id);
CREATE INDEX idx_opportunity_products_org_customer ON sales.opportunity_products(organization_id, customer_id);

CREATE INDEX idx_proposals_organization_id ON sales.proposals(organization_id);

CREATE INDEX idx_proposal_items_organization_id ON sales.proposal_items(organization_id);
CREATE INDEX idx_proposal_items_customer_id ON sales.proposal_items(customer_id);
CREATE INDEX idx_proposal_items_org_customer ON sales.proposal_items(organization_id, customer_id);

CREATE INDEX idx_interactions_organization_id ON sales.interactions(organization_id);

CREATE INDEX idx_interaction_notes_organization_id ON sales.interaction_notes(organization_id);
CREATE INDEX idx_interaction_notes_customer_id ON sales.interaction_notes(customer_id);
CREATE INDEX idx_interaction_notes_org_customer ON sales.interaction_notes(organization_id, customer_id);

-- Support schema indexes
CREATE INDEX idx_documents_organization_id ON support.documents(organization_id);

CREATE INDEX idx_document_approvals_organization_id ON support.document_approvals(organization_id);
CREATE INDEX idx_document_approvals_customer_id ON support.document_approvals(customer_id);
CREATE INDEX idx_document_approvals_org_customer ON support.document_approvals(organization_id, customer_id);

CREATE INDEX idx_support_tickets_organization_id ON support.support_tickets(organization_id);

-- Index for root organization lookup
CREATE INDEX idx_organizations_is_root ON auth.organizations(is_root_organization);