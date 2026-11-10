-- preload: pg_squeeze
-- https://github.com/cybertec-postgresql/pg_squeeze
CREATE EXTENSION pg_squeeze;

-- A table left mostly empty by deletions.
CREATE TABLE bloated (id integer PRIMARY KEY, payload text);
ALTER TABLE bloated SET (autovacuum_enabled = FALSE);
INSERT INTO bloated
SELECT
    i,
    repeat('x', 100)
FROM generate_series(1, 20000) AS i;
DELETE FROM bloated
WHERE id % 10 <> 0;
CREATE TEMPORARY TABLE sizes AS SELECT pg_relation_size('bloated') AS before;

SELECT squeeze.squeeze_table('public', 'bloated');

SELECT plan(2);
SELECT ok(
    (SELECT pg_relation_size('bloated') < before / 4 FROM sizes),
    'tables are rewritten without their dead space'
);
SELECT is((SELECT count(*) FROM bloated), 2000::bigint, 'rows are kept');
SELECT * FROM finish(TRUE);
