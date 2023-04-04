CREATE TABLE accounts (
    id         UUID PRIMARY KEY,
    username   TEXT NOT NULL,
    name       TEXT NOT NULL,
    avatar_url TEXT
);
CREATE UNIQUE INDEX accounts_unique_username ON accounts (UPPER(username));

CREATE TABLE content_managers (
    account_id UUID PRIMARY KEY REFERENCES accounts (id),
    name       TEXT NOT NULL,
    avatar_url TEXT
);

CREATE TABLE article_cards (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title       TEXT NOT NULL,
    description TEXT NOT NULL,
    image_url   TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by  UUID NOT NULL REFERENCES content_managers (account_id)
);
CREATE INDEX article_cards_created_by_fkey ON article_cards (created_by);

CREATE TABLE articles (
    article_id  UUID PRIMARY KEY REFERENCES article_cards (id) ON DELETE CASCADE,
    content     TEXT NOT NULL,
    source_name TEXT,
    source_link TEXT
);

CREATE TABLE tags (
    id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE
);
CREATE INDEX tags_name ON tags (UPPER(name));

CREATE TABLE article_tags (
    article_id UUID REFERENCES article_cards (id) ON DELETE CASCADE,
    tag_id     UUID REFERENCES tags (id) ON DELETE CASCADE,
    PRIMARY KEY (article_id, tag_id)
);
CREATE UNIQUE INDEX article_tags_pkey_reverse ON article_tags (tag_id, article_id);

CREATE TABLE account_favorites (
    account_id UUID REFERENCES accounts (id),
    article_id UUID REFERENCES article_cards (id) ON DELETE CASCADE,
    added_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (account_id, article_id)
);

CREATE OR REPLACE FUNCTION find_all_articles_by_filter(
    tag_ids UUID[]
)
    RETURNS SETOF UUID
AS
$$
BEGIN
    IF tag_ids IS NULL OR CARDINALITY(tag_ids) = 0 THEN
        RETURN QUERY
            SELECT ac.id
            FROM article_cards AS ac
            ORDER BY ac.created_at DESC;
        RETURN;
    END IF;

    RETURN QUERY
        SELECT ac.id
        FROM article_cards AS ac
                 INNER JOIN article_tags AS at ON ac.id = at.article_id
        WHERE at.tag_id = ANY (tag_ids)
        GROUP BY ac.id, ac.created_at
        ORDER BY ac.created_at DESC;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION find_all_content_manager_articles_by_filter(
    content_manager_id UUID,
    tag_ids UUID[]
)
    RETURNS SETOF UUID
AS
$$
BEGIN
    IF tag_ids IS NULL OR CARDINALITY(tag_ids) = 0 THEN
        RETURN QUERY
            SELECT ac.id
            FROM article_cards AS ac
            WHERE ac.created_by = content_manager_id
            ORDER BY ac.created_at DESC;
        RETURN;
    END IF;

    RETURN QUERY
        SELECT ac.id
        FROM article_cards AS ac
                 INNER JOIN article_tags AS at ON ac.id = at.article_id
        WHERE ac.created_by = content_manager_id
          AND at.tag_id = ANY (tag_ids)
        GROUP BY ac.id, ac.created_at
        ORDER BY ac.created_at DESC;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION find_favorite_articles(
    account_id UUID
)
    RETURNS SETOF UUID
AS
$$
BEGIN
    RETURN QUERY
        SELECT af.article_id
        FROM account_favorites AS af
        WHERE af.account_id = $1
        ORDER BY af.added_at DESC;
END;
$$ LANGUAGE PLPGSQL;

-- CREATE SUBSCRIPTION accounts_subscription_for_news_feed_service CONNECTION '...' PUBLICATION accounts_publication;