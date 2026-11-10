-- https://github.com/timescale/pgvectorscale
CREATE EXTENSION vectorscale CASCADE;  -- requires vector

CREATE TABLE document_embedding (id bigint PRIMARY KEY, embedding vector(3));
INSERT INTO document_embedding
SELECT
	i,
	ARRAY[sin(i), cos(i), sin(2 * i)]::vector(3)
FROM generate_series(1, 2000) AS i;
CREATE INDEX document_embedding_idx ON document_embedding USING diskann (embedding vector_cosine_ops);
ANALYZE document_embedding;
SELECT set_config('enable_seqscan', 'off', FALSE);

SELECT plan(2);
SELECT is(
	(
		SELECT id FROM document_embedding
		ORDER BY
			embedding <=> (
				SELECT q.embedding FROM document_embedding AS q
				WHERE q.id = 42
			)
		LIMIT 1
	),
	42::bigint,
	'StreamingDiskANN finds the nearest vector'
);
SELECT matches(
	plan_of('SELECT id FROM document_embedding ORDER BY embedding <=> ''[0.5,0.5,0.5]'' LIMIT 5'),
	'document_embedding_idx',
	'nearest-neighbour searches use the DiskANN index'
);
SELECT * FROM finish(TRUE);
