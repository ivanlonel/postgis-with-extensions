-- preload: vchord
-- https://github.com/supervc-stack/VectorChord
CREATE EXTENSION vchord CASCADE;  -- requires vector

CREATE TABLE items (id bigint PRIMARY KEY, embedding vector(3));
-- Seeded random vectors: no near-duplicates, the same on every run.
SELECT setseed(0.42);
INSERT INTO items
SELECT
	i,
	ARRAY[random(), random(), random()]::vector(3)
FROM generate_series(1, 2000) AS i;
CREATE INDEX items_vchordrq_idx ON items USING vchordrq (embedding vector_l2_ops);
ANALYZE items;
SELECT set_config('enable_seqscan', 'off', FALSE);

SELECT plan(2);
SELECT is(
	(
		SELECT id FROM items
		ORDER BY embedding <-> (
			SELECT q.embedding FROM items AS q
			WHERE q.id = 42
		) LIMIT 1
	),
	42::bigint,
	'vchordrq finds the nearest vector'
);
SELECT matches(
	plan_of('SELECT id FROM items ORDER BY embedding <-> ''[0.5,0.5,0.5]'' LIMIT 5'),
	'items_vchordrq_idx',
	'nearest-neighbour searches use the vchordrq index'
);
SELECT * FROM finish(TRUE);
