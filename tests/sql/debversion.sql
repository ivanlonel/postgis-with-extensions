-- https://salsa.debian.org/postgresql/postgresql-debversion
CREATE EXTENSION debversion;

SELECT plan(5);
SELECT is(
    (
        SELECT max(v::debversion)::text
        FROM unnest(ARRAY[
            '4.1.5-2', '4.0.2-1', '4.1.4-1', '4.1.5-1', '4.2.0-1', '4.1.4-2', '4.1.5-2.01',
            '4.1.99-a2-1', '5.2.1-2', '5.0.0-3', '5.1.98.2-2', '3.1.4-1', '5.2.3-1',
            '0:5.2.2-1', '0:5.2.4-1', '1:3.2.3-1'
        ]) AS v
    ),
    '1:3.2.3-1',
    'versions sort by epoch first'
);
SELECT ok('1.0~rc1-1'::debversion < '1.0-1'::debversion, 'a tilde sorts before anything');
SELECT ok('1.0-1'::debversion < '1.0-1+b1'::debversion, 'binary NMUs sort after their source');
SELECT ok('1.10-1'::debversion > '1.9-1'::debversion, 'numbers compare numerically');
SELECT ok('2.0-1'::debversion = '0:2.0-1'::debversion, 'a missing epoch is zero');
SELECT * FROM finish(TRUE);
