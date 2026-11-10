-- preload: pg_textsearch
-- pg: >=17
-- https://github.com/timescale/pg_textsearch
CREATE EXTENSION pg_textsearch;

CREATE TABLE documents (id serial PRIMARY KEY, content text);
INSERT INTO documents (content) VALUES
('PostgreSQL is a powerful, open source object-relational database system'),
('PostGIS adds support for geographic objects to PostgreSQL'),
('Cats sleep most of the day');
INSERT INTO documents (content)
SELECT 'Filler document number ' || i FROM generate_series(1, 2000) AS i;

CREATE INDEX docs_idx ON documents USING bm25 (content) WITH (text_config = 'english');
ANALYZE documents;
SELECT set_config('enable_seqscan', 'off', FALSE);

SELECT plan(2);
SELECT is(
	-- (The linter can't parse pg_textsearch's <@> (BM25 score) operator, nor lay out what follows.)
	(SELECT id FROM documents ORDER BY content <@> 'geographic objects' LIMIT 1),  -- noqa: PRS, LT14
	2,
	'BM25 ranks the best match first'
);
SELECT matches(
	plan_of($$SELECT id FROM documents ORDER BY content <@> 'geographic objects' LIMIT 1$$),
	'docs_idx',
	'ranked searches use the BM25 index'
);
SELECT * FROM finish(TRUE);
