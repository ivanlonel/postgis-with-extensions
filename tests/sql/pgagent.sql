-- https://github.com/pgadmin-org/pgagent
-- The pgagent daemon itself is exercised by tests/test_binaries.py.
CREATE EXTENSION pgagent;

-- A job with one SQL step, scheduled every minute from an hour ago until tomorrow.
DO $$
DECLARE
	jid integer;
BEGIN
	INSERT INTO pgagent.pga_job (jobjclid, jobname, jobdesc, jobhostagent, jobenabled)
	VALUES (1, 'Routine Clean', '', '', TRUE)
	RETURNING jobid INTO jid;

	INSERT INTO pgagent.pga_jobstep (
		jstjobid, jstname, jstenabled, jstkind, jstconnstr, jstdbname, jstonerror, jstcode, jstdesc
	) VALUES (
		jid, 'Clean_News', TRUE, 's', '', current_database(), 'f', 'SELECT 1', ''
	);

	INSERT INTO pgagent.pga_schedule (
		jscjobid, jscname, jscdesc, jscenabled, jscstart, jscend,
		jscminutes, jschours, jscweekdays, jscmonthdays, jscmonths
	) VALUES (
		jid, 'Every minute', '', TRUE, now() - INTERVAL '1 hour', now() + INTERVAL '1 day',
		array_fill(TRUE, ARRAY[60]), array_fill(TRUE, ARRAY[24]), array_fill(TRUE, ARRAY[7]),
		array_fill(TRUE, ARRAY[32]), array_fill(TRUE, ARRAY[12])
	);
END
$$;

SELECT plan(2);
SELECT is(
	(SELECT count(*) FROM pgagent.pga_jobstep INNER JOIN pgagent.pga_job ON jstjobid = jobid),
	1::bigint,
	'jobs and steps are stored'
);
SELECT ok(
	(SELECT jobnextrun BETWEEN now() - interval '2 minutes' AND now() + interval '2 minutes' FROM pgagent.pga_job),
	'schedules set the next run'
);
SELECT * FROM finish(TRUE);
