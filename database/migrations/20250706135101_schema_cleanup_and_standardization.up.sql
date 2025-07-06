-- Schema Cleanup and Standardization Migration
-- This migration implements the following changes:
-- 1. Remove columns from accounting.bank_accounts (organization_id, company_id, balance)
-- 2. Remove columns from accounting.banks (website, routing_number, country, swift_code)
-- 3. Add visibility column to config.catalog_types
-- 4. Standardize code values in config.catalog_types

-- Step 1: Remove columns from accounting.bank_accounts
ALTER TABLE accounting.bank_accounts DROP COLUMN IF EXISTS organization_id;
ALTER TABLE accounting.bank_accounts DROP COLUMN IF EXISTS company_id;
ALTER TABLE accounting.bank_accounts DROP COLUMN IF EXISTS balance;

-- Step 2: Remove columns from accounting.banks
ALTER TABLE accounting.banks DROP COLUMN IF EXISTS website;
ALTER TABLE accounting.banks DROP COLUMN IF EXISTS routing_number;
ALTER TABLE accounting.banks DROP COLUMN IF EXISTS country;
ALTER TABLE accounting.banks DROP COLUMN IF EXISTS swift_code;

-- Step 3: Add visibility column to config.catalog_types
ALTER TABLE config.catalog_types ADD COLUMN is_visible BOOLEAN DEFAULT TRUE;

-- Step 4: Standardize code values in config.catalog_types
-- Convert all codes to lowercase and ensure proper naming convention
UPDATE config.catalog_types SET code = LOWER(code);

-- Update specific codes to follow table_column naming pattern
-- Note: These updates are based on common patterns, actual values may need adjustment
UPDATE config.catalog_types SET code = 'bank_account_type' WHERE code = 'bankaccounttype' OR code = 'bank_account_types';
UPDATE config.catalog_types SET code = 'payment_method' WHERE code = 'paymentmethod' OR code = 'payment_methods';
UPDATE config.catalog_types SET code = 'currency_type' WHERE code = 'currencytype' OR code = 'currency_types';
UPDATE config.catalog_types SET code = 'transaction_type' WHERE code = 'transactiontype' OR code = 'transaction_types';
UPDATE config.catalog_types SET code = 'invoice_status' WHERE code = 'invoicestatus' OR code = 'invoice_statuses';
UPDATE config.catalog_types SET code = 'company_type' WHERE code = 'companytype' OR code = 'company_types';
UPDATE config.catalog_types SET code = 'contact_type' WHERE code = 'contacttype' OR code = 'contact_types';
UPDATE config.catalog_types SET code = 'address_type' WHERE code = 'addresstype' OR code = 'address_types';
UPDATE config.catalog_types SET code = 'phone_type' WHERE code = 'phonetype' OR code = 'phone_types';
UPDATE config.catalog_types SET code = 'email_type' WHERE code = 'emailtype' OR code = 'email_types';
UPDATE config.catalog_types SET code = 'document_type' WHERE code = 'documenttype' OR code = 'document_types';
UPDATE config.catalog_types SET code = 'product_type' WHERE code = 'producttype' OR code = 'product_types';
UPDATE config.catalog_types SET code = 'service_type' WHERE code = 'servicetype' OR code = 'service_types';
UPDATE config.catalog_types SET code = 'agreement_type' WHERE code = 'agreementtype' OR code = 'agreement_types';
UPDATE config.catalog_types SET code = 'agreement_status' WHERE code = 'agreementstatus' OR code = 'agreement_statuses';
UPDATE config.catalog_types SET code = 'billing_frequency' WHERE code = 'billingfrequency' OR code = 'billing_frequencies';
UPDATE config.catalog_types SET code = 'payment_term' WHERE code = 'paymentterm' OR code = 'payment_terms';
UPDATE config.catalog_types SET code = 'tax_type' WHERE code = 'taxtype' OR code = 'tax_types';
UPDATE config.catalog_types SET code = 'discount_type' WHERE code = 'discounttype' OR code = 'discount_types';
UPDATE config.catalog_types SET code = 'credit_type' WHERE code = 'credittype' OR code = 'credit_types';
UPDATE config.catalog_types SET code = 'support_priority' WHERE code = 'supportpriority' OR code = 'support_priorities';
UPDATE config.catalog_types SET code = 'support_status' WHERE code = 'supportstatus' OR code = 'support_statuses';
UPDATE config.catalog_types SET code = 'support_category' WHERE code = 'supportcategory' OR code = 'support_categories';
UPDATE config.catalog_types SET code = 'notification_type' WHERE code = 'notificationtype' OR code = 'notification_types';
UPDATE config.catalog_types SET code = 'user_status' WHERE code = 'userstatus' OR code = 'user_statuses';
UPDATE config.catalog_types SET code = 'role_type' WHERE code = 'roletype' OR code = 'role_types';
UPDATE config.catalog_types SET code = 'permission_type' WHERE code = 'permissiontype' OR code = 'permission_types';

-- Set visibility to false for internal-only catalog types
-- These are system-level configurations that shouldn't be visible in the dashboard
UPDATE config.catalog_types SET is_visible = FALSE 
WHERE code IN (
    'system_config',
    'internal_status',
    'audit_type',
    'log_level',
    'system_role',
    'internal_permission'
);