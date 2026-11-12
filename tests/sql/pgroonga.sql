-- image: extended
-- https://github.com/pgroonga/pgroonga
CREATE EXTENSION pgroonga;

CREATE TABLE memos (id integer PRIMARY KEY, content text NOT NULL);
INSERT INTO memos VALUES
(1, 'PostgreSQL is a relational database management system.'),
(2, 'Groonga is a fast full text search engine that supports all languages.'),
(3, 'PGroonga is a PostgreSQL extension that uses Groonga as index.'),
(4, 'ポスグレはリレーショナル・データベース管理システムです。');
CREATE INDEX memos_content_idx ON memos USING pgroonga (content);
SELECT set_config('enable_seqscan', 'off', FALSE);

SELECT plan(4);
SELECT results_eq(
    $$SELECT id FROM memos WHERE content &@~ 'groonga' ORDER BY id$$,
    ARRAY[2, 3],
    'full-text searches find every matching row'
);
SELECT results_eq(
    $$SELECT id FROM memos WHERE content &@~ 'データベース' ORDER BY id$$,
    ARRAY[4],
    'searches work in Japanese, which has no spaces between words'
);
SELECT matches(
    plan_of($$SELECT id FROM memos WHERE content &@~ 'groonga'$$),
    'memos_content_idx',
    'searches use the PGroonga index'
);
SELECT results_eq(
    $$
        SELECT id FROM memos WHERE content &@~ 'PostgreSQL OR database'
        ORDER BY pgroonga_score(tableoid, ctid) DESC, id LIMIT 1
    $$,
    ARRAY[1],
    'rows matching more terms score higher'
);
SELECT * FROM finish(TRUE);
