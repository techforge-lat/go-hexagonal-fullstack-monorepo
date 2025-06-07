-- Enable UUID extension for uuid_generate_v4() function
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA IF NOT EXISTS auth;

-- Create user origin enum table
CREATE TABLE auth.users_origin_enum
(
    code VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

COMMENT ON TABLE auth.users_origin_enum IS 'Enumeration table for user origin types.';
COMMENT ON COLUMN auth.users_origin_enum.code IS 'Unique code identifier for the origin type (primary key).';
COMMENT ON COLUMN auth.users_origin_enum.name IS 'Human-readable name for the origin type.';

-- Insert default origin values
INSERT INTO auth.users_origin_enum (code, name) VALUES
('SYSTEM', 'System'),
('CMS', 'Content Management System'),
('APP', 'Application'),
('MOBILE', 'Mobile Application'),
('DESKTOP', 'Desktop Application');

CREATE TABLE auth.users
(
    id         UUID             DEFAULT uuid_generate_v4()         NOT NULL
        PRIMARY KEY,
    origin     VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL
        REFERENCES auth.users_origin_enum(code),
    first_name VARCHAR(100)     DEFAULT ''::character varying      NOT NULL,
    last_name  VARCHAR(100),
    picture    TEXT,
    created_at TIMESTAMP WITH TIME ZONE      DEFAULT NOW()                    NOT NULL,
    created_by UUID
        REFERENCES auth.users,
    updated_at TIMESTAMP WITH TIME ZONE,
    updated_by UUID
        REFERENCES auth.users,
	deleted_at TIMESTAMP WITH TIME ZONE,
	deleted_by UUID
		REFERENCES auth.users
);

COMMENT ON TABLE auth.users IS 'Stores information about each user.';

COMMENT ON COLUMN auth.users.id IS 'Unique identifier for each user.';
COMMENT ON COLUMN auth.users.origin IS 'Source system or origin of the user account.';
COMMENT ON COLUMN auth.users.first_name IS 'User''s first name.';
COMMENT ON COLUMN auth.users.last_name IS 'User''s last name (optional).';
COMMENT ON COLUMN auth.users.picture IS 'URL or path to user''s profile picture (optional).';
COMMENT ON COLUMN auth.users.created_at IS 'Timestamp when the user record was created.';
COMMENT ON COLUMN auth.users.created_by IS 'ID of the user who created this record.';
COMMENT ON COLUMN auth.users.updated_at IS 'Timestamp when the user record was last updated.';
COMMENT ON COLUMN auth.users.updated_by IS 'ID of the user who last updated this record.';
COMMENT ON COLUMN auth.users.deleted_at IS 'Timestamp when the user was soft deleted (NULL if not deleted).';
COMMENT ON COLUMN auth.users.deleted_by IS 'ID of the user who performed the soft delete operation.';
