-- https://github.com/vyruss/pg_statviz
CREATE EXTENSION pg_statviz;

SELECT pgstatviz.snapshot();
SELECT pg_sleep(1);
SELECT pgstatviz.snapshot();

SELECT plan(4);
SELECT is((SELECT count(*) FROM pgstatviz.snapshots), 2::bigint, 'statistics are snapshotted');
SELECT is((SELECT count(*) FROM pgstatviz.conn), 2::bigint, 'connection statistics are kept');
SELECT is((SELECT count(*) FROM pgstatviz.buf), 2::bigint, 'buffer statistics are kept');
SELECT ok((SELECT count(*) > 0 FROM pgstatviz.conf), 'settings are kept');
SELECT * FROM finish(TRUE);
