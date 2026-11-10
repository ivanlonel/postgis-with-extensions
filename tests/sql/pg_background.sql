-- https://github.com/vibhorkum/pg_background
CREATE EXTENSION pg_background;

SELECT plan(1);
SELECT ok(
	(
		SELECT completed AND NOT has_error
		FROM pg_background_run('SELECT 1', queue_size := 0, timeout_ms := 60000, label := 'smoke')
	),
	'SQL runs in a background worker'
);
SELECT * FROM finish(TRUE);
