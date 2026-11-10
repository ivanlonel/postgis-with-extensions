-- https://github.com/timescale/pgvectorscale
CREATE EXTENSION vectorscale CASCADE;  -- requires vector

CREATE TABLE document_embedding (id bigserial PRIMARY KEY, embedding vector(3));
INSERT INTO document_embedding (embedding) VALUES ('[1,2,3]'), ('[4,5,6]'), ('[-1,-2,-3]');
CREATE INDEX document_embedding_idx ON document_embedding USING diskann (embedding vector_cosine_ops);

SELECT plan(1);
SELECT is(
	(
		SELECT id FROM document_embedding
		ORDER BY embedding <=> '[1,2,3]' LIMIT 1
	),
	1::bigint,
	'StreamingDiskANN finds the nearest vector'
);
SELECT * FROM finish(TRUE);
