-- https://github.com/pgvector/pgvector
CREATE EXTENSION vector;

CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3));
INSERT INTO items (embedding) VALUES ('[1,2,3]'), ('[4,5,6]');
CREATE INDEX ON items USING hnsw (embedding vector_l2_ops);

SELECT plan(1);
SELECT is(
	(
		SELECT id FROM items
		ORDER BY embedding <-> '[3,1,2]' LIMIT 1
	), 1::bigint, 'nearest neighbour'
);
SELECT * FROM finish(TRUE);
