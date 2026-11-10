-- https://github.com/omniti-labs/pg_jobmon
CREATE SCHEMA jobmon;
CREATE EXTENSION pg_jobmon SCHEMA jobmon CASCADE;  -- requires dblink

-- Jobs log through dblink, so their logs survive the caller's rollback.
DO $$
DECLARE
	job bigint;
	step bigint;
BEGIN
	job := jobmon.add_job('PWE NIGHTLY LOAD');
	step := jobmon.add_step(job, 'Load the rows');
	PERFORM jobmon.update_step(step, 'OK', 'Loaded 42 rows');
	PERFORM jobmon.close_job(job);

	job := jobmon.add_job('PWE FAILING LOAD');
	step := jobmon.add_step(job, 'Load the rows');
	PERFORM jobmon.fail_job(job);
END
$$;

SELECT plan(3);
SELECT is((
	SELECT status FROM jobmon.job_log
	WHERE job_name = 'PWE NIGHTLY LOAD'
), 'OK', 'jobs are logged');
SELECT is(
	(
		SELECT d.message FROM jobmon.job_detail AS d
		INNER JOIN jobmon.job_log AS l ON d.job_id = l.job_id
		WHERE l.job_name = 'PWE NIGHTLY LOAD'
	),
	'Loaded 42 rows',
	'steps are logged'
);
SELECT is(
	(
		SELECT status FROM jobmon.job_log
		WHERE job_name = 'PWE FAILING LOAD'
	),
	'CRITICAL',
	'failures are logged'
);
SELECT * FROM finish(TRUE);
