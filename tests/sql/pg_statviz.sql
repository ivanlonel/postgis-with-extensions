-- https://github.com/vyruss/pg_statviz
CREATE EXTENSION pg_statviz;

SELECT pgstatviz.snapshot();

SELECT plan(1);
SELECT is((SELECT count(*) FROM pgstatviz.snapshots), 1::bigint, 'statistics are snapshotted');
SELECT * FROM finish(TRUE);
