-- https://github.com/fboulnois/pg_uuidv7
CREATE EXTENSION pg_uuidv7;

SELECT plan(3);
SELECT is(substr(uuid_generate_v7()::text, 15, 1), '7', 'UUIDs are version 7');
SELECT ok(
	abs(extract(EPOCH FROM uuid_v7_to_timestamptz(uuid_generate_v7()) - clock_timestamp())) < 5,
	'UUIDs embed the current time'
);
SELECT is(
	uuid_v7_to_timestamptz(uuid_timestamptz_to_v7('2024-01-01 00:00:00+00', TRUE)),
	'2024-01-01 00:00:00+00'::timestamptz,
	'timestamps round-trip through UUIDs'
);
SELECT * FROM finish(TRUE);
