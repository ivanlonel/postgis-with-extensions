-- https://codeberg.org/pgsql_tweaks/pgsql_tweaks
CREATE EXTENSION pgsql_tweaks;

SELECT plan(13);
SELECT ok(is_date('2018-01-01'), 'valid dates are recognized');
SELECT ok(NOT is_date('2018-02-31'), 'invalid dates are rejected');
SELECT ok(is_date('01.01.2018', 'DD.MM.YYYY'), 'dates are checked against formats');
SELECT ok(is_time('14:33:55.456574') AND NOT is_time('25:33:55.456574'), 'times are checked');
SELECT ok(is_timestamp('01.01.2018 00:00:00', 'DD.MM.YYYY HH24.MI.SS'), 'timestamps are checked');
SELECT ok(is_real('123.456') AND NOT is_real('123,456'), 'reals are checked');
SELECT ok(is_numeric('123') AND NOT is_numeric('1 2'), 'numerics are checked');
SELECT ok(is_bigint('9876543210') AND NOT is_integer('9876543210'), 'integer ranges are checked');
SELECT ok(is_boolean('yes') AND is_boolean('F') AND NOT is_boolean('maybe'), 'booleans are checked');
SELECT ok(is_json('{"a": 1}') AND NOT is_json('{a: 1}'), 'JSON is checked');
SELECT ok(is_hex('a1b0') AND NOT is_hex('g1'), 'hexadecimal strings are checked');
SELECT is(hex2bigint('a1b0'), 41392::bigint, 'hexadecimal strings convert');
SELECT is(to_unix_timestamp('2018-01-01 00:00:00+01'), 1514761200::bigint, 'Unix timestamps');
SELECT * FROM finish(TRUE);
