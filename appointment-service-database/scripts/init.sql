CREATE TABLE accounts (
    id         UUID PRIMARY KEY,
    username   TEXT NOT NULL,
    name       TEXT NOT NULL,
    avatar_url TEXT
);
CREATE UNIQUE INDEX accounts_unique_username ON accounts (UPPER(username));

-- CREATE SUBSCRIPTION accounts_subscription_for_appointment_service CONNECTION '...' PUBLICATION accounts_publication;

CREATE TABLE user_families (
    user_id   UUID REFERENCES accounts (id),
    family_id UUID,
    PRIMARY KEY (user_id, family_id)
);
CREATE UNIQUE INDEX user_families_pkey_reverse ON user_families (family_id, user_id);

CREATE TABLE pets (
    id         UUID PRIMARY KEY,
    name       TEXT NOT NULL,
    avatar_url TEXT,
    family_id  UUID,
    created_by UUID NOT NULL REFERENCES accounts (id)
);
CREATE INDEX pets_created_by_fkey ON pets (created_by);
CREATE INDEX pets_family_fkey ON pets (family_id);

-- CREATE SUBSCRIPTION pets_subscription_for_appointment_service CONNECTION '...' PUBLICATION pets_publication;

CREATE TABLE vets (
    account_id UUID PRIMARY KEY REFERENCES accounts (id),
    name       TEXT NOT NULL,
    avatar_url TEXT,
    available  BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE time_slots (
    id         INTEGER PRIMARY KEY,
    start_time TIME WITH TIME ZONE NOT NULL UNIQUE,
    end_time   TIME WITH TIME ZONE NOT NULL UNIQUE,
    CHECK (start_time < end_time)
);

CREATE TABLE vet_schedule (
    id           UUID PRIMARY KEY,
    vet_id       UUID NOT NULL REFERENCES vets (account_id),
    time_slot_id INTEGER NOT NULL REFERENCES time_slots (id) ON DELETE CASCADE,
    monday       BOOLEAN NOT NULL DEFAULT FALSE,
    tuesday      BOOLEAN NOT NULL DEFAULT FALSE,
    wednesday    BOOLEAN NOT NULL DEFAULT FALSE,
    thursday     BOOLEAN NOT NULL DEFAULT FALSE,
    friday       BOOLEAN NOT NULL DEFAULT FALSE,
    saturday     BOOLEAN NOT NULL DEFAULT FALSE,
    sunday       BOOLEAN NOT NULL DEFAULT FALSE,
    CHECK (monday OR tuesday OR wednesday OR thursday OR friday OR saturday OR sunday),
    UNIQUE (vet_id, time_slot_id)
);
CREATE INDEX vet_schedule_vet_fkey ON vet_schedule (vet_id);

-- CREATE SUBSCRIPTION vets_subscription_for_appointment_service CONNECTION '...' PUBLICATION vets_publication;

CREATE TYPE appointment_status AS ENUM ('SCHEDULED', 'CANCELED', 'COMPLETED');
CREATE CAST (VARCHAR AS appointment_status) WITH INOUT AS IMPLICIT;

CREATE TABLE appointments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    problem         TEXT NOT NULL,
    connection_link TEXT,
    diagnosis       TEXT,
    recommendations TEXT,
    status          appointment_status NOT NULL DEFAULT 'SCHEDULED',
    scheduled_at    TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    vet_id          UUID NOT NULL REFERENCES vets (account_id),
    client_id       UUID NOT NULL REFERENCES accounts (id),
    pet_id          UUID NOT NULL REFERENCES pets (id) ON DELETE CASCADE,
    UNIQUE (vet_id, scheduled_at)
);
CREATE INDEX appointments_vet_fkey ON appointments (vet_id);
CREATE INDEX appointments_client_fkey ON appointments (client_id);
CREATE INDEX appointments_pet_fkey ON appointments (pet_id);

CREATE FUNCTION find_free_vet_time_slots_by_date(
    vet_id UUID,
    date DATE
)
    RETURNS SETOF TIME_SLOTS
AS
$$
DECLARE
    day_of_week INTEGER := EXTRACT(ISODOW FROM date);
BEGIN
    RETURN QUERY
        SELECT ts.*
        FROM time_slots AS ts
                 INNER JOIN vet_schedule AS vs ON ts.id = vs.time_slot_id
        WHERE vs.vet_id = $1
          AND CASE day_of_week
                  WHEN 1 THEN vs.monday = TRUE
                  WHEN 2 THEN vs.tuesday = TRUE
                  WHEN 3 THEN vs.wednesday = TRUE
                  WHEN 4 THEN vs.thursday = TRUE
                  WHEN 5 THEN vs.friday = TRUE
                  WHEN 6 THEN vs.saturday = TRUE
                  WHEN 7 THEN vs.sunday = TRUE
            END
          AND NOT EXISTS(SELECT 1
                         FROM appointments AS a
                         WHERE a.vet_id = $1
                           AND a.scheduled_at = date + ts.start_time
                           AND a.status = 'SCHEDULED');
END;
$$ LANGUAGE PLPGSQL;

CREATE FUNCTION pet_is_associated_with_user(pet_id UUID, user_id UUID)
    RETURNS BOOLEAN
AS
$$
BEGIN
    RETURN EXISTS(SELECT 1
                  FROM pets AS p
                  WHERE p.id = $1
                    AND p.created_by = $2) OR
           EXISTS(SELECT 1
                  FROM pets AS p
                           INNER JOIN user_families AS uf ON p.family_id = uf.family_id
                  WHERE p.id = $1
                    AND uf.user_id = $2);
END;
$$ LANGUAGE PLPGSQL;