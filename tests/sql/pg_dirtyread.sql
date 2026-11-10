-- https://github.com/df7cb/pg_dirtyread
CREATE EXTENSION pg_dirtyread;

CREATE TABLE foo (bar bigint, baz text);
ALTER TABLE foo SET (autovacuum_enabled = FALSE, toast.autovacuum_enabled = FALSE);

INSERT INTO foo VALUES (1, 'Test'), (2, 'New Test');
DELETE FROM foo
WHERE bar = 1;
UPDATE foo SET baz = 'Updated'
WHERE bar = 2;

SELECT plan(4);
SELECT is((SELECT count(*) FROM foo), 1::bigint, 'one row is visible');
SELECT is(
	(SELECT count(*) FROM pg_dirtyread('foo') AS t (bar bigint, baz text)),
	3::bigint,
	'deleted and updated row versions are still readable'
);
SELECT is(
	(
		SELECT baz FROM pg_dirtyread('foo') AS t (bar bigint, baz text)
		WHERE bar = 1
	),
	'Test',
	'deleted rows keep their contents'
);
SELECT ok(
	(
		SELECT xmax <> '0' FROM pg_dirtyread('foo') AS t (xmax xid, bar bigint, baz text)
		WHERE bar = 1
	),
	'system columns are read'
);
SELECT * FROM finish(TRUE);
