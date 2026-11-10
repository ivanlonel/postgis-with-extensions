-- preload: pg_partman_bgw
-- database: partman
-- https://github.com/pgpartman/pg_partman
-- The background worker runs maintenance in pg_partman_bgw.dbname, as pg_partman_bgw.role.
CREATE SCHEMA IF NOT EXISTS partman;
CREATE EXTENSION IF NOT EXISTS pg_partman SCHEMA partman;

CREATE TABLE public.bgw_events (id integer, at date NOT NULL) PARTITION BY RANGE (at);
SELECT partman.create_parent('public.bgw_events', p_control := 'at', p_interval := '1 day', p_premake := 1);
CREATE TEMPORARY TABLE initial AS
SELECT count(*) AS partitions FROM partman.show_partitions('public.bgw_events');
-- Four more days ahead: the next maintenance run creates their partitions (even though the set
-- holds no data, which otherwise stops time-based sets from growing).
UPDATE partman.part_config SET premake = 5, infinite_time_partitions = TRUE
WHERE parent_table = 'public.bgw_events';

-- Have the worker run every second, as the superuser, then put the settings back. (sqlfluff
-- can't parse ALTER SYSTEM.)
ALTER SYSTEM SET pg_partman_bgw.interval = 1;  -- noqa: PRS
ALTER SYSTEM SET pg_partman_bgw.role = 'postgres';  -- noqa: PRS
SELECT pg_reload_conf();

SELECT plan(1);
SELECT ok(
	wait_until($$
		SELECT count(*) >= (SELECT partitions + 4 FROM initial)
		FROM partman.show_partitions('public.bgw_events')
	$$),
	'the background worker runs maintenance'
);

ALTER SYSTEM RESET pg_partman_bgw.interval;  -- noqa: PRS
ALTER SYSTEM RESET pg_partman_bgw.role;  -- noqa: PRS
SELECT pg_reload_conf();
SELECT * FROM finish(TRUE);

DROP TABLE public.bgw_events;
DELETE FROM partman.part_config
WHERE parent_table = 'public.bgw_events';
