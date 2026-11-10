-- preload: vchord
-- https://github.com/supervc-stack/VectorChord
CREATE EXTENSION vchord CASCADE;  -- requires vector

CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3));
INSERT INTO items (embedding) VALUES ('[1,2,3]'), ('[4,5,6]'), ('[-1,-2,-3]');
CREATE INDEX ON items USING vchordrq (embedding vector_l2_ops);

SELECT plan(1);
SELECT is(
	(
		SELECT id FROM items
		ORDER BY embedding <-> '[1,2,3]' LIMIT 1
	), 1::bigint, 'vchordrq finds the nearest vector'
);
SELECT * FROM finish(TRUE);
