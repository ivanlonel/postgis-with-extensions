-- https://github.com/vibhorkum/pg_background
CREATE EXTENSION pg_background;

CREATE TABLE written_in_background (id integer);

-- Workers are identified by a handle: their pid and a cookie.
CREATE TEMPORARY TABLE answer AS
SELECT r.result
FROM
	(SELECT pg_background_launch('SELECT 40 + 2') AS h) AS l,
	pg_background_result((l.h).pid, (l.h).cookie) AS r (result integer);
-- The worker commits on its own: the row outlives this session's transaction.
CREATE TEMPORARY TABLE inserted AS
SELECT r.status
FROM
	(SELECT pg_background_launch('INSERT INTO written_in_background VALUES (1)') AS h) AS l,
	pg_background_result((l.h).pid, (l.h).cookie) AS r (status text);

SELECT plan(3);
SELECT ok(
	(
		SELECT completed AND NOT has_error
		FROM pg_background_run('SELECT 1', queue_size := 0, timeout_ms := 60000, label := 'smoke')
	),
	'SQL runs in a background worker'
);
SELECT is((SELECT result FROM answer), 42, 'results come back');
SELECT is((SELECT count(*) FROM written_in_background), 1::bigint, 'writes commit independently');
SELECT * FROM finish(TRUE);
