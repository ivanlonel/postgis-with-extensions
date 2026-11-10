-- https://github.com/orafce/orafce
CREATE EXTENSION orafce;

SELECT plan(1);
SELECT is(
	oracle.add_months(oracle.date '2021-05-31 10:12:12', 1)::text,
	'2021-06-30 10:12:12',
	'add_months moves to the last day of the month'
);
SELECT * FROM finish(TRUE);
