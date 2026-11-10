-- https://github.com/fvannee/timestamp9
CREATE EXTENSION timestamp9;

SELECT plan(1);
SELECT is((1::bigint::timestamp9)::bigint, 1::bigint, 'nanosecond timestamps round-trip');
SELECT * FROM finish(TRUE);
