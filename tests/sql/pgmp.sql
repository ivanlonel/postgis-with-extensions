-- https://github.com/dvarrazzo/pgmp
CREATE EXTENSION pgmp;

SELECT plan(5);
SELECT is((10.1::numeric::mpq)::text, '101/10', 'rationals');
SELECT is(
    (9223372036854775807::mpz * 2)::text, '18446744073709551614', 'arbitrary-precision integers'
);
SELECT is((2::mpz ^ 100)::text, '1267650600228229401496703205376', 'powers');
SELECT is(gcd(12::mpz, 18::mpz)::text, '6', 'greatest common divisors');
SELECT is(nextprime(1000000::mpz)::text, '1000003', 'primes');
SELECT * FROM finish(TRUE);
