-- preload: pg_cron
-- database: cron
-- https://github.com/citusdata/pg_cron
CREATE EXTENSION IF NOT EXISTS pg_cron;

CREATE TABLE cron_ticks (at timestamptz NOT NULL DEFAULT now());
SELECT cron.schedule('pwe-tick', '1 seconds', 'INSERT INTO cron_ticks DEFAULT VALUES');

SELECT plan(4);
SELECT ok(wait_until('SELECT count(*) > 0 FROM cron_ticks'), 'scheduled jobs run');
SELECT ok(
	wait_until($$
		SELECT count(*) > 0 FROM cron.job_run_details AS d
		INNER JOIN cron.job AS j ON d.jobid = j.jobid
		WHERE j.jobname = 'pwe-tick' AND d.status = 'succeeded'
	$$),
	'runs are recorded'
);
SELECT cron.unschedule('pwe-tick');
SELECT is((
	SELECT count(*) FROM cron.job
	WHERE jobname = 'pwe-tick'
), 0::bigint, 'jobs are unscheduled');
SELECT cmp_ok(cron.schedule('pwe-nightly', '0 3 * * *', 'VACUUM'), '>', 0::bigint, 'cron schedules are accepted');
SELECT cron.unschedule('pwe-nightly');
SELECT * FROM finish(TRUE);

DROP TABLE cron_ticks;
