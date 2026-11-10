-- preload: pg_textsearch
-- pg: >=17
-- https://github.com/timescale/pg_textsearch
CREATE EXTENSION pg_textsearch;

CREATE TABLE documents (id serial PRIMARY KEY, content text);
INSERT INTO documents (content) VALUES
('PostgreSQL is a powerful, open source object-relational database system'),
('PostGIS adds support for geographic objects to PostgreSQL'),
('Cats sleep most of the day');

CREATE INDEX docs_idx ON documents USING bm25 (content) WITH (text_config = 'english');

SELECT plan(1);
SELECT is(
	-- sqlfluff can't parse pg_textsearch's <@> (BM25 score) operator, nor lay out what follows.
	(SELECT id FROM documents ORDER BY content <@> 'geographic objects' LIMIT 1),  -- noqa: PRS, LT14
	2,
	'BM25 ranks the best match first'
);
SELECT * FROM finish(TRUE);
