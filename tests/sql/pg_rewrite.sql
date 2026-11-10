-- preload: pg_rewrite
-- https://github.com/cybertec-postgresql/pg_rewrite
CREATE EXTENSION pg_rewrite;

SELECT plan(1);
SELECT ok(
	EXISTS (
		SELECT FROM pg_proc
		WHERE proname = 'rewrite_table'
	), 'rewrite_table is installed'
);
SELECT * FROM finish(TRUE);
