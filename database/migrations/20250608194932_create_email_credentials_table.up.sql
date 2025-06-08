CREATE TABLE auth.email_credentials
(
    id            UUID      DEFAULT uuid_generate_v4() NOT NULL
        PRIMARY KEY,
    user_id       UUID                                 NOT NULL
        UNIQUE
        REFERENCES auth.users,
    email         VARCHAR(255)                         NOT NULL
        UNIQUE,
    password_hash VARCHAR(255),
    is_verified   BOOLEAN   DEFAULT FALSE,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()              NOT NULL,
    created_by    UUID
        REFERENCES auth.users,
    updated_at    TIMESTAMP WITH TIME ZONE,
    updated_by    UUID
        REFERENCES auth.users
);

COMMENT ON TABLE auth.email_credentials IS 'Stores email credentials for users.';

COMMENT ON COLUMN auth.email_credentials.id IS 'Unique identifier for each email credential.';

COMMENT ON COLUMN auth.email_credentials.user_id IS 'Reference to the user.';

COMMENT ON COLUMN auth.email_credentials.email IS 'Email address of the user.';

COMMENT ON COLUMN auth.email_credentials.password_hash IS 'Hashed password for email authentication.';

COMMENT ON COLUMN auth.email_credentials.is_verified IS 'Whether the email address has been verified.';

COMMENT ON COLUMN auth.email_credentials.created_at IS 'Timestamp when the email credential was created.';

COMMENT ON COLUMN auth.email_credentials.created_by IS 'Reference to the user who created this email credential.';

COMMENT ON COLUMN auth.email_credentials.updated_at IS 'Timestamp when the email credential was last updated.';

COMMENT ON COLUMN auth.email_credentials.updated_by IS 'Reference to the user who last updated this email credential.';

