-- https://codeberg.org/pgsql_tweaks/pgsql_tweaks
CREATE EXTENSION pgsql_tweaks;

SELECT
	is_date('2018-01-01'),
	is_date('2018-02-31'),
	is_date('01.01.2018', 'DD.MM.YYYY');
SELECT
	is_time('14:33:55.456574'),
	is_time('25:33:55.456574'),
	is_time('14.33.55,456574', 'HH24.MI.SS,US');
SELECT
	is_timestamp('2018-01-01 00:00:00'),
	is_timestamp('01.01.2018 00:00:00', 'DD.MM.YYYY HH24.MI.SS');
SELECT
	is_real('123.456'),
	is_real('123,456'),
	is_double_precision('123.456'),
	is_double_precision('123,456');
SELECT
	is_numeric('123'),
	is_numeric('1 2'),
	is_bigint('9876543210'),
	is_integer('98765'),
	is_smallint('321');
SELECT
	is_boolean('yes'),
	is_boolean('false'),
	is_boolean('NO'),
	is_boolean('TRUE'),
	is_boolean('1'),
	is_boolean('F');
SELECT is_json('{"review": {"date": "1970-12-30", "votes": 10}, "customer_id": "AE22YDHSBFYIP"}');
SELECT is_jsonb('{"review": {"date": "1970-12-30", "votes": 10}, "customer_id": "AE22YDHSBFYIP"}');
SELECT
	is_hex('a1b0'),
	is_hex('a1b0c3c3c3c4b5d3'),
	hex2bigint('a1b0');
SELECT sha256('test-string'::bytea);
SELECT pg_size_pretty(pg_schema_size('public'));
SELECT
	is_encoding('ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝ', 'LATIN1'),
	is_encoding('àáâãäåçèéêëìíîïñòóôõöùúûüýÿ', 'LATIN1', 'UTF8');
SELECT return_not_part_of_encoding('ağbƵcğeƵ', 'latin1');
SELECT to_unix_timestamp('2018-01-01 00:00:00+01');
SELECT array_trim(ARRAY['2018-11-11 11:00:00 MEZ', NULL, '2018-11-11 11:00:00 MEZ']::timestamp with time zone[], TRUE);

SELECT plan(2);
SELECT ok(is_date('2018-01-01'), 'valid dates are recognized');
SELECT ok(NOT is_date('2018-02-31'), 'invalid dates are rejected');
SELECT * FROM finish(TRUE);
