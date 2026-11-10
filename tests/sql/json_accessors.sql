-- https://github.com/theirix/json_accessors
CREATE EXTENSION json_accessors;

SELECT plan(12);
SELECT is(json_get_text('{"foo":"qq", "bar": true}', 'foo'), 'qq', 'text values');
SELECT is(json_get_boolean('{"foo":"qq", "bar": true}', 'bar'), TRUE, 'boolean values');
SELECT is(json_get_int('{"baz": 42, "boo": 42.424242}', 'baz'), 42, 'integer values');
SELECT is(json_get_bigint('{"baz": 9223372036854, "boo": 42.424242}', 'baz'), 9223372036854, 'bigint values');
SELECT is(json_get_numeric('{"baz": 42, "boo": 42.424242}', 'boo'), 42.424242, 'numeric values');
SELECT is(
    json_get_timestamp('{"foo":"qq", "bar": "2009-12-01 01:23:45"}', 'bar'),
    '2009-12-01 01:23:45'::timestamp,
    'timestamp values'
);
SELECT is(json_get_text('{"foo":"qq", "bar": true}', 'noneofthese'), NULL, 'missing keys are null');
SELECT is(json_get_text('{"foo":null, "bar": true}', 'foo'), NULL, 'null values are null');
SELECT is(json_array_to_int_array('[42, 43]'), ARRAY[42, 43], 'arrays convert');
SELECT is(
    json_get_text_array('{"foo":"qq", "bar": ["baz1", "baz2", "baz3"]}', 'bar'),
    ARRAY['baz1', 'baz2', 'baz3'],
    'nested arrays are extracted'
);
SELECT ok(
    json_get_object('{"foo":"qq", "bar": {"baz1": "baz2"}}', 'bar')::jsonb = '{"baz1": "baz2"}'::jsonb,
    'nested objects are extracted'
);
SELECT is(
    json_get_object_keys('{"foo":"qq", "bar": ["baz1", "baz2", "baz3"]}'),
    ARRAY['foo', 'bar'],
    'object keys are listed'
);
SELECT * FROM finish(TRUE);
