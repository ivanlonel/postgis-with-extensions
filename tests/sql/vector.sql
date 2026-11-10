-- https://github.com/pgvector/pgvector
CREATE EXTENSION vector;

CREATE TABLE items (id bigint PRIMARY KEY, embedding vector(3));
-- Seeded random vectors: no near-duplicates, the same on every run.
SELECT setseed(0.42);
INSERT INTO items
SELECT
	i,
	ARRAY[random(), random(), random()]::vector(3)
FROM generate_series(1, 2000) AS i;
CREATE INDEX items_hnsw_idx ON items USING hnsw (embedding vector_l2_ops);
CREATE INDEX items_ivfflat_idx ON items USING ivfflat (embedding vector_cosine_ops) WITH (lists = 10);
ANALYZE items;
SELECT set_config('enable_seqscan', 'off', FALSE);
SELECT set_config('ivfflat.probes', '10', FALSE);

SELECT plan(8);
SELECT is(round(('[1,2,3]'::vector <-> '[4,5,6]')::numeric, 6), 5.196152, 'Euclidean distance');
SELECT is('[1,2,3]'::vector <#> '[4,5,6]', -32::float8, 'negative inner product');
SELECT is(cosine_distance('[1,0]'::vector, '[0,1]'::vector), 1::float8, 'cosine distance');
SELECT is(round(('[1,2,3]'::halfvec <-> '[4,5,6]')::numeric, 2), 5.20, 'half-precision vectors');
SELECT is(
	(SELECT avg(embedding) FROM (VALUES ('[1,2,3]'::vector), ('[3,4,5]')) AS v (embedding)),
	'[2,3,4]'::vector,
	'vectors average'
);
SELECT is(
	(
		SELECT id FROM items
		ORDER BY embedding <-> (
			SELECT q.embedding FROM items AS q
			WHERE q.id = 42
		) LIMIT 1
	),
	42::bigint,
	'HNSW finds the nearest neighbour'
);
SELECT matches(
	plan_of('SELECT id FROM items ORDER BY embedding <-> ''[0.5,0.5,0.5]'' LIMIT 5'),
	'items_hnsw_idx',
	'nearest-neighbour searches use the HNSW index'
);
SELECT is(
	(
		SELECT id FROM items
		ORDER BY embedding <=> (
			SELECT q.embedding FROM items AS q
			WHERE q.id = 42
		) LIMIT 1
	),
	42::bigint,
	'IVFFlat finds the nearest neighbour'
);
SELECT * FROM finish(TRUE);
