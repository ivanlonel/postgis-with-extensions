-- https://github.com/df7cb/postgresql-unit
CREATE EXTENSION unit;

SELECT plan(1);
SELECT is(('9.81 N'::unit / 'kg')::text, '9.81 m/s^2', 'units are derived');
SELECT * FROM finish(TRUE);
