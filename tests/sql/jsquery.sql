-- https://github.com/postgrespro/jsquery
CREATE EXTENSION jsquery;

CREATE TABLE docs (id integer PRIMARY KEY, doc jsonb);
INSERT INTO docs
SELECT
	i,
	jsonb_build_object('id', i, 'tags', jsonb_build_array('t' || (i % 10)), 'price', i % 100)
FROM generate_series(1, 10000) AS i;
CREATE INDEX docs_doc_idx ON docs USING gin (doc jsonb_path_value_ops);
ANALYZE docs;
SELECT set_config('enable_seqscan', 'off', FALSE);

SELECT plan(4);
SELECT ok(
	'{"x": true}' @@ 'x IS boolean'::jsquery
	AND '{"x": 0.1}' @@ 'x IS numeric'::jsquery
	AND '{"a": {"b": 1}}' @@ 'a IS object'::jsquery
	AND '{"a": ["xxx"]}' @@ 'a IS array AND a.#: IS string'::jsquery
	AND '["xxx"]' @@ '$ IS array'::jsquery
	AND '{"points": [{"x": 1, "y": 2}, {"x": 3.9, "y": 0.5}]}'
	@@ 'points.#:(x IS numeric AND y IS numeric)'::jsquery,
	'jsquery matches documents'
);
SELECT ok(NOT '{"x": 1}' @@ 'x IS string'::jsquery, 'jsquery rejects documents');
SELECT is(
	(
		SELECT count(*) FROM docs
		WHERE doc @@ 'tags.# = "t3" AND price < 50'::jsquery
	),
	500::bigint,
	'queries combine conditions'
);
SELECT matches(
	plan_of($$SELECT * FROM docs WHERE doc @@ 'tags.# = "t3"'::jsquery$$),
	'docs_doc_idx',
	'queries use the GIN index'
);
SELECT * FROM finish(TRUE);
