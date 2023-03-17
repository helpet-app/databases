CREATE TABLE accounts (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username          TEXT NOT NULL UNIQUE CHECK (LENGTH(username) >= 4),
    password          TEXT NOT NULL CHECK (LENGTH(password) > 0),
    name              TEXT NOT NULL CHECK (LENGTH(name) > 0),
    email             TEXT NOT NULL UNIQUE CHECK (LENGTH(email) > 0),
    is_email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_enabled        BOOLEAN NOT NULL DEFAULT TRUE,
    is_blocked        BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TYPE role AS ENUM ('ADMIN', 'MODERATOR', 'CLINIC_REPRESENTATIVE', 'VET', 'USER');
CREATE CAST (VARCHAR AS role) WITH INOUT AS IMPLICIT;

CREATE TABLE account_roles (
    account_id UUID REFERENCES accounts (id) ON DELETE CASCADE,
    role       role NOT NULL,
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

CREATE TABLE account_bans (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id   UUID NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
    moderator_id UUID REFERENCES accounts (id) ON DELETE SET NULL CHECK (account_has_role(moderator_id, 'MODERATOR')),
    blocked_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    unblocked_at TIMESTAMPTZ CHECK (unblocked_at > blocked_at),
    reason       TEXT NOT NULL CHECK (LENGTH(reason) > 0)
);
CREATE INDEX IF NOT EXISTS account_bans_account_fkey ON account_bans (account_id);
CREATE INDEX IF NOT EXISTS account_bans_moderator_id_fkey ON account_bans (moderator_id);

CREATE OR REPLACE FUNCTION block_account() RETURNS TRIGGER AS
$$
BEGIN
    UPDATE accounts SET is_blocked = NEW.unblocked_at IS NULL WHERE id = NEW.account_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER block_account_trigger
    AFTER INSERT OR UPDATE
    ON account_bans
    FOR EACH ROW
EXECUTE PROCEDURE block_account();

ALTER SYSTEM SET wal_level = logical;

CREATE PUBLICATION accounts_publication FOR TABLE accounts (id, username, name, email, is_email_verified, is_enabled, is_blocked), account_roles WITH (PUBLISH = 'INSERT,UPDATE,DELETE,TRUNCATE');
