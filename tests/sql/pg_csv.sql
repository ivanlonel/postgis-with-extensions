-- https://github.com/PostgREST/pg_csv
CREATE EXTENSION pg_csv;

SELECT plan(1);
SELECT matches(
	(SELECT csv_agg(x) FROM (VALUES (1, 'one'), (2, 'two')) AS x (id, name)),
	'2,two',
	'rows aggregate to CSV'
);
SELECT * FROM finish(TRUE);
