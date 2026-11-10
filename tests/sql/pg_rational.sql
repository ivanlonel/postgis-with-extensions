-- https://github.com/begriffs/pg_rational
CREATE EXTENSION pg_rational;

SELECT plan(1);
SELECT is((0.263157894737::float::rational)::text, '5/19', 'floats convert to fractions');
SELECT * FROM finish(TRUE);
