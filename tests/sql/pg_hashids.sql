-- https://github.com/iCyberon/pg_hashids
CREATE EXTENSION pg_hashids;

SELECT plan(2);
SELECT is(id_encode(1001), 'jNl', 'ids are encoded');
SELECT is(
	id_decode(id_encode(1234567, 'This is my salt', 10), 'This is my salt', 10),
	ARRAY[1234567]::bigint[],
	'ids are decoded'
);
SELECT * FROM finish(TRUE);
