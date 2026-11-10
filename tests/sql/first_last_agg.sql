-- https://github.com/wulczer/first_last_agg
CREATE EXTENSION first_last_agg;

SELECT plan(3);
SELECT is(
	(SELECT last(x ORDER BY y) FROM (VALUES (1, 3), (2, 1), (3, 2)) AS v (x, y)), 1, 'last'
);
SELECT is(
	(SELECT first(x ORDER BY y) FROM (VALUES (1, 3), (2, 1), (3, 2)) AS v (x, y)), 2, 'first'
);
SELECT is(
	(
		SELECT array_agg(f ORDER BY g)
		FROM (
			SELECT
				g,
				first(x ORDER BY y) AS f
			FROM (VALUES (1, 1, 'a'), (1, 2, 'b'), (2, 2, 'c'), (2, 1, 'd')) AS v (g, y, x)
			GROUP BY g
		) AS firsts
	),
	ARRAY['a', 'd'],
	'per group'
);
SELECT * FROM finish(TRUE);
