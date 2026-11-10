-- https://github.com/df7cb/postgresql-unit
CREATE EXTENSION unit;

SELECT plan(5);
SELECT is(('9.81 N'::unit / 'kg')::text, '9.81 m/s^2', 'units are derived');
SELECT is(('1 s'::unit + '2 min'::unit)::text, '121 s', 'compatible quantities add up');
SELECT is('1 km'::unit @ 'm', '1000 m', 'quantities convert');
SELECT ok('1 km'::unit > '999 m'::unit, 'quantities compare across prefixes');
SELECT throws_ok($$SELECT '1 m'::unit + '1 s'::unit$$, NULL, NULL, 'mismatched dimensions are rejected');
SELECT * FROM finish(TRUE);
