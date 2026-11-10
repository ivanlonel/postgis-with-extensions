-- https://github.com/wulczer/first_last_agg
CREATE EXTENSION first_last_agg;

SELECT plan(2);
SELECT is(
	(SELECT last(x ORDER BY y) FROM (VALUES (1, 3), (2, 1), (3, 2)) AS v (x, y)), 1, 'last'
);
SELECT is(
	(SELECT first(x ORDER BY y) FROM (VALUES (1, 3), (2, 1), (3, 2)) AS v (x, y)), 2, 'first'
);
SELECT * FROM finish(TRUE);
