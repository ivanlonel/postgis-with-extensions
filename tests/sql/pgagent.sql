-- https://github.com/pgadmin-org/pgagent
CREATE EXTENSION pgagent;

-- Create a pgAgent job (https://karatejb.blogspot.com/2020/04/postgresql-pgagent-scheduling-agent.html)
DO $$
DECLARE
	jid integer;
BEGIN
	INSERT INTO pgagent.pga_job (jobjclid, jobname, jobdesc, jobhostagent, jobenabled)
	VALUES (1, 'Routine Clean', '', '', true)
	RETURNING jobid INTO jid;

	INSERT INTO pgagent.pga_jobstep (
		jstjobid, jstname, jstenabled, jstkind, jstconnstr, jstdbname, jstonerror, jstcode, jstdesc
	) VALUES (
		jid, 'Clean_News', true, 's',
		'host=localhost port=5432 dbname=postgres connect_timeout=10 user=''postgres''', '', 'f',
		'DELETE FROM public."News"', ''
	);

	INSERT INTO pgagent.pga_schedule (
		jscjobid, jscname, jscdesc, jscenabled, jscstart, jscend,
		jscminutes, jschours, jscweekdays, jscmonthdays, jscmonths
	) VALUES (
		jid, 'Daily', '', true, '2020-04-24 06:14:44+00', '2020-04-30 05:51:17+00',
		array_fill(false, ARRAY[60]), array_fill(false, ARRAY[24]), array_fill(false, ARRAY[7]),
		array_fill(false, ARRAY[32]), array_fill(false, ARRAY[12])
	);
END
$$;

SELECT plan(1);
SELECT is(
	(SELECT count(*) FROM pgagent.pga_jobstep INNER JOIN pgagent.pga_job ON jstjobid = jobid),
	1::bigint,
	'jobs and steps are stored'
);
SELECT * FROM finish(TRUE);
