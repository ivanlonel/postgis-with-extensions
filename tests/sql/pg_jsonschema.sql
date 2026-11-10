-- https://github.com/supabase/pg_jsonschema
CREATE EXTENSION pg_jsonschema;

SELECT plan(2);
SELECT ok(json_matches_schema('{"type": "object"}', '{}'), 'documents matching the schema pass');
SELECT ok(NOT jsonb_matches_schema('{"maxLength": 4}', '"123456789"'), 'documents violating it fail');
SELECT * FROM finish(TRUE);
