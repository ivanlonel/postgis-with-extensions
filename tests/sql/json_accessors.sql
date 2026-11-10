-- https://github.com/theirix/json_accessors
CREATE EXTENSION json_accessors;

SELECT json_get_text('{"foo":"qq", "bar": true}', 'foo');
SELECT json_get_boolean('{"foo":"qq", "bar": true}', 'bar');
SELECT json_get_int('{"baz": 42, "boo": 42.424242}', 'baz');
SELECT json_get_bigint('{"baz": 9223372036854, "boo": 42.424242}', 'baz');
SELECT json_get_numeric('{"baz": 42, "boo": 42.424242}', 'boo');
SELECT json_get_text('{"foo":"qq", "bar": true}', 'noneofthese') IS NULL;
SELECT json_get_text('{"foo":null, "bar": true}', 'foo') IS NULL;
SELECT json_get_timestamp('{"foo":"qq", "bar": "2009-12-01 01:23:45"}', 'bar');

SELECT json_array_to_text_array('["foo", "bar"]');
SELECT json_array_to_boolean_array('[true, false]');
SELECT json_array_to_int_array('[42, 43]');
SELECT json_array_to_bigint_array('[42, 9223372036854]');
SELECT json_array_to_numeric_array('[42.4242,43.4343]');
SELECT json_array_to_timestamp_array('["2009-12-01 01:23:45", "2012-12-01 01:23:45"]');
SELECT json_get_text_array('{"foo":"qq", "bar": ["baz1", "baz2", "baz3"]}', 'bar');

SELECT json_get_boolean_array('{"foo":"qq", "bar": [true, false]}', 'bar');
SELECT json_get_int_array('{"foo":"qq", "bar": [42, 43]}', 'bar');
SELECT json_get_bigint_array('{"foo":"qq", "bar": [42, 9223372036854]}', 'bar');
SELECT json_get_numeric_array('{"foo":"qq", "bar": [42.4242,43.4343]}', 'bar');
SELECT json_get_timestamp_array('{"foo":"qq", "bar": ["2009-12-01 01:23:45", "2012-12-01 01:23:45"]}', 'bar');

SELECT json_get_object('{"foo":"qq", "bar": ["baz1", "baz2", "baz3"]}', 'foo');
SELECT json_get_object('{"foo":"qq", "bar": ["baz1", "baz2", "baz3"]}', 'bar');
SELECT json_get_object('{"foo":"qq", "bar": {"baz1": "baz2"}}', 'bar');
SELECT json_array_to_object_array('[{"foo":42}, {"bar":[]}]');
SELECT json_get_object_keys('{"foo":"qq", "bar": ["baz1", "baz2", "baz3"]}');

SELECT plan(1);
SELECT is(json_get_text('{"foo":"qq", "bar": true}', 'foo'), 'qq', 'json_get_text');
SELECT * FROM finish(TRUE);
