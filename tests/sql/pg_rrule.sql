-- https://github.com/petropavel13/pg_rrule
CREATE EXTENSION pg_rrule;

SELECT get_freq('FREQ=WEEKLY;INTERVAL=1;WKST=MO;UNTIL=20200101T045102Z'::rrule);
SELECT get_byday('FREQ=WEEKLY;INTERVAL=1;WKST=MO;UNTIL=20200101T045102Z;BYDAY=MO,TH,SU'::rrule);

SELECT plan(1);
SELECT is(
	(
		SELECT count(*)
		FROM unnest(get_occurrences(
			'FREQ=WEEKLY;INTERVAL=1;WKST=MO;UNTIL=20200101T045102Z;BYDAY=SA;BYHOUR=10;BYMINUTE=51;BYSECOND=2'::rrule,
			'2019-12-07 10:51:02+00'::timestamp
		))
	),
	4::bigint,
	'occurrences are expanded'
);
SELECT * FROM finish(TRUE);
