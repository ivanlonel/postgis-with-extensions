-- https://github.com/rjuju/pg_track_settings
CREATE EXTENSION pg_track_settings;

SELECT pg_track_settings_snapshot();
CREATE TEMPORARY TABLE marks AS SELECT clock_timestamp() AS before_change;
SELECT set_config('work_mem', '7MB', FALSE);
SELECT pg_track_settings_snapshot();

SELECT plan(1);
SELECT is(
	(
		SELECT to_setting FROM marks, pg_track_settings_diff(before_change, clock_timestamp())
		WHERE name = 'work_mem'
	),
	'7168',
	'setting changes are tracked'
);
SELECT * FROM finish(TRUE);
