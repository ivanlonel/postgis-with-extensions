-- https://github.com/df7cb/pg_dirtyread
CREATE EXTENSION pg_dirtyread;

CREATE TABLE foo (bar bigint, baz text);
ALTER TABLE foo SET (autovacuum_enabled = FALSE, toast.autovacuum_enabled = FALSE);

INSERT INTO foo VALUES (1, 'Test'), (2, 'New Test');
DELETE FROM foo
WHERE bar = 1;

SELECT plan(1);
SELECT is(
	(SELECT count(*) FROM pg_dirtyread('foo') AS t (bar bigint, baz text)),
	2::bigint,
	'deleted rows are still readable'
);
SELECT * FROM finish(TRUE);
