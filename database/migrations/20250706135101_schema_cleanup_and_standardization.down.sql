-- Rollback Schema Cleanup and Standardization Migration
-- This migration reverses the following changes:
-- 1. Restore columns to accounting.bank_accounts (organization_id, company_id, balance)
-- 2. Restore columns to accounting.banks (website, routing_number, country, swift_code)
-- 3. Remove visibility column from config.catalog_types
-- 4. Restore original code values in config.catalog_types

-- Step 1: Restore columns to accounting.bank_accounts
ALTER TABLE accounting.bank_accounts ADD COLUMN organization_id UUID;
ALTER TABLE accounting.bank_accounts ADD COLUMN company_id UUID;
ALTER TABLE accounting.bank_accounts ADD COLUMN balance DECIMAL(15,2) DEFAULT 0.00;

-- Add foreign key constraints back
ALTER TABLE accounting.bank_accounts 
ADD CONSTRAINT fk_bank_accounts_organization 
FOREIGN KEY (organization_id) REFERENCES auth.organizations(id) ON DELETE CASCADE;

ALTER TABLE accounting.bank_accounts 
ADD CONSTRAINT fk_bank_accounts_company 
FOREIGN KEY (company_id) REFERENCES relationships.companies(id) ON DELETE CASCADE;

-- Step 2: Restore columns to accounting.banks
ALTER TABLE accounting.banks ADD COLUMN website VARCHAR(255);
ALTER TABLE accounting.banks ADD COLUMN routing_number VARCHAR(20);
ALTER TABLE accounting.banks ADD COLUMN country VARCHAR(100);
ALTER TABLE accounting.banks ADD COLUMN swift_code VARCHAR(11);

-- Step 3: Remove visibility column from config.catalog_types
ALTER TABLE config.catalog_types DROP COLUMN IF EXISTS is_visible;

-- Step 4: Restore original code values in config.catalog_types
-- Note: This restoration assumes the original format was camelCase or similar
-- Actual original values may need to be adjusted based on backup data
UPDATE config.catalog_types SET code = 'bankAccountType' WHERE code = 'bank_account_type';
UPDATE config.catalog_types SET code = 'paymentMethod' WHERE code = 'payment_method';
UPDATE config.catalog_types SET code = 'currencyType' WHERE code = 'currency_type';
UPDATE config.catalog_types SET code = 'transactionType' WHERE code = 'transaction_type';
UPDATE config.catalog_types SET code = 'invoiceStatus' WHERE code = 'invoice_status';
UPDATE config.catalog_types SET code = 'companyType' WHERE code = 'company_type';
UPDATE config.catalog_types SET code = 'contactType' WHERE code = 'contact_type';
UPDATE config.catalog_types SET code = 'addressType' WHERE code = 'address_type';
UPDATE config.catalog_types SET code = 'phoneType' WHERE code = 'phone_type';
UPDATE config.catalog_types SET code = 'emailType' WHERE code = 'email_type';
UPDATE config.catalog_types SET code = 'documentType' WHERE code = 'document_type';
UPDATE config.catalog_types SET code = 'productType' WHERE code = 'product_type';
UPDATE config.catalog_types SET code = 'serviceType' WHERE code = 'service_type';
UPDATE config.catalog_types SET code = 'agreementType' WHERE code = 'agreement_type';
UPDATE config.catalog_types SET code = 'agreementStatus' WHERE code = 'agreement_status';
UPDATE config.catalog_types SET code = 'billingFrequency' WHERE code = 'billing_frequency';
UPDATE config.catalog_types SET code = 'paymentTerm' WHERE code = 'payment_term';
UPDATE config.catalog_types SET code = 'taxType' WHERE code = 'tax_type';
UPDATE config.catalog_types SET code = 'discountType' WHERE code = 'discount_type';
UPDATE config.catalog_types SET code = 'creditType' WHERE code = 'credit_type';
UPDATE config.catalog_types SET code = 'supportPriority' WHERE code = 'support_priority';
UPDATE config.catalog_types SET code = 'supportStatus' WHERE code = 'support_status';
UPDATE config.catalog_types SET code = 'supportCategory' WHERE code = 'support_category';
UPDATE config.catalog_types SET code = 'notificationType' WHERE code = 'notification_type';
UPDATE config.catalog_types SET code = 'userStatus' WHERE code = 'user_status';
UPDATE config.catalog_types SET code = 'roleType' WHERE code = 'role_type';
UPDATE config.catalog_types SET code = 'permissionType' WHERE code = 'permission_type';