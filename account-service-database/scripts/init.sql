CREATE TABLE accounts (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username          TEXT NOT NULL,
    password          TEXT NOT NULL,
    name              TEXT NOT NULL,
    email             TEXT NOT NULL,
    avatar_url        TEXT,
    is_email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_enabled        BOOLEAN NOT NULL DEFAULT TRUE,
    is_blocked        BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE UNIQUE INDEX accounts_unique_username ON accounts (UPPER(username));
CREATE UNIQUE INDEX accounts_unique_email ON accounts (UPPER(email));

CREATE TYPE role AS ENUM ('ADMIN', 'MODERATOR', 'CLINIC_REPRESENTATIVE', 'VET', 'CONTENT_MANAGER', 'USER');
CREATE CAST (VARCHAR AS role) WITH INOUT AS IMPLICIT;

CREATE TABLE account_roles (
    account_id UUID REFERENCES accounts (id),
    role       role,
    PRIMARY KEY (account_id, role)
);

CREATE OR REPLACE FUNCTION account_has_role(account_id UUID, role role) RETURNS BOOLEAN AS
$$
BEGIN
    IF (EXISTS(SELECT 1 FROM account_roles WHERE account_roles.account_id = $1 AND account_roles.role = $2)) THEN
        RETURN TRUE;
    END IF;

    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

ALTER SYSTEM SET wal_level = logical;

CREATE PUBLICATION accounts_publication FOR TABLE accounts (id, username, NAME, avatar_url) WITH (PUBLISH = 'INSERT,UPDATE,DELETE,TRUNCATE');
