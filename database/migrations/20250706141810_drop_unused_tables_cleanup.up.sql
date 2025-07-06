-- Drop Unused Tables Cleanup Migration
-- This migration drops the following tables:
-- 1. billing.credit_applications
-- 2. billing.credit_note_items
-- 3. billing.credit_notes
-- 4. billing.customer_support_services
-- 5. support.documents
-- 6. support.support_tickets

BEGIN;

-- Drop tables in correct order to handle foreign key constraints
-- Drop child tables first, then parent tables

-- Drop billing.credit_applications (references credit_notes)
DROP TABLE IF EXISTS billing.credit_applications CASCADE;

-- Drop billing.credit_note_items (references credit_notes)
DROP TABLE IF EXISTS billing.credit_note_items CASCADE;

-- Drop billing.credit_notes (main parent table)
DROP TABLE IF EXISTS billing.credit_notes CASCADE;

-- Drop support.support_tickets (references customer_support_services)
DROP TABLE IF EXISTS support.support_tickets CASCADE;

-- Drop billing.customer_support_services
DROP TABLE IF EXISTS billing.customer_support_services CASCADE;

-- Drop support.documents (has self-referencing constraints)
DROP TABLE IF EXISTS support.documents CASCADE;

COMMIT;