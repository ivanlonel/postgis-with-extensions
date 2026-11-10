-- https://github.com/dvarrazzo/pgmp
CREATE EXTENSION pgmp;

SELECT plan(2);
SELECT is((10.1::numeric::mpq)::text, '101/10', 'rationals');
SELECT is(
	(9223372036854775807::mpz * 2)::text, '18446744073709551614', 'arbitrary-precision integers'
);
SELECT * FROM finish(TRUE);
