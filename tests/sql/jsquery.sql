-- https://github.com/postgrespro/jsquery
CREATE EXTENSION jsquery;

SELECT plan(1);
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
SELECT * FROM finish(TRUE);
