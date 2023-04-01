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
CREATE INDEX IF NOT EXISTS article_cards_created_by_fkey ON article_cards (created_by);

CREATE TABLE articles (
    article_id  UUID PRIMARY KEY REFERENCES article_cards (id) ON DELETE CASCADE,
    content     TEXT NOT NULL,
    source_name TEXT,
    source_link TEXT
);

CREATE TABLE tags (
    id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL
);
CREATE UNIQUE INDEX tags_unique_name ON tags (UPPER(name));

CREATE TABLE article_tags (
    article_id UUID REFERENCES article_cards (id) ON DELETE CASCADE,
    tag_id     UUID REFERENCES tags (id) ON DELETE CASCADE,
    PRIMARY KEY (article_id, tag_id)
);
CREATE UNIQUE INDEX IF NOT EXISTS article_tags_pkey_reverse ON article_tags (tag_id, article_id);

CREATE TABLE account_favorites (
    account_id UUID REFERENCES accounts (id),
    article_id UUID REFERENCES article_cards (id) ON DELETE CASCADE,
    PRIMARY KEY (account_id, article_id)
);

-- CREATE SUBSCRIPTION accounts_subscription_for_news_feed_service CONNECTION '...' PUBLICATION accounts_publication;