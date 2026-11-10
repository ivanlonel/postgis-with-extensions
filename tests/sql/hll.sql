-- https://github.com/citusdata/postgresql-hll
CREATE EXTENSION hll;

SELECT plan(1);
SELECT ok(
	(
		SELECT abs(hll_cardinality(hll_add_agg(hll_hash_integer(n))) - 1000) < 50
		FROM generate_series(1, 1000) AS n
	),
	'distinct values are estimated'
);
SELECT * FROM finish(TRUE);
