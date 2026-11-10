-- https://github.com/petropavel13/pg_rrule
CREATE EXTENSION pg_rrule;

SELECT plan(4);
SELECT is(
	get_freq('FREQ=WEEKLY;INTERVAL=1;WKST=MO;UNTIL=20200101T045102Z'::rrule)::text,
	'WEEKLY',
	'rules are parsed'
);
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
SELECT is(
	(
		SELECT min(o)::timestamp
		FROM unnest(get_occurrences(
			'FREQ=WEEKLY;INTERVAL=1;WKST=MO;UNTIL=20200101T045102Z;BYDAY=SA;BYHOUR=10;BYMINUTE=51;BYSECOND=2'::rrule,
			'2019-12-07 10:51:02+00'::timestamp
		)) AS o
	),
	'2019-12-07 10:51:02'::timestamp,
	'occurrences start at the start'
);
SELECT is(
	(SELECT count(*) FROM unnest(get_occurrences('FREQ=DAILY;COUNT=10'::rrule, '2024-01-01 00:00:00'::timestamp))),
	10::bigint,
	'counted rules stop after their count'
);
SELECT * FROM finish(TRUE);
