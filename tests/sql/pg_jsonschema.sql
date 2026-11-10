-- https://github.com/supabase/pg_jsonschema
CREATE EXTENSION pg_jsonschema;

-- Schemas typically guard jsonb columns through check constraints.
CREATE TABLE customers (
	id serial PRIMARY KEY,
	metadata jsonb CHECK (
		jsonb_matches_schema(
			'{"type": "object", "properties": {"tags": {"type": "array", "items": {"type": "string"}}}, "required": ["tags"]}',
			metadata
		)
	)
);
INSERT INTO customers (metadata) VALUES ('{"tags": ["vip", "darkmode-ui"]}');

SELECT plan(5);
SELECT ok(json_matches_schema('{"type": "object"}', '{}'), 'documents matching the schema pass');
SELECT ok(NOT jsonb_matches_schema('{"maxLength": 4}', '"123456789"'), 'documents violating it fail');
SELECT ok(
	jsonschema_is_valid('{"type": "object"}') AND NOT jsonschema_is_valid('{"type": 42}'),
	'schemas are validated'
);
SELECT is((SELECT count(*) FROM customers), 1::bigint, 'valid rows are accepted');
SELECT throws_ok(
	$$INSERT INTO customers (metadata) VALUES ('{"tags": [1, 2]}')$$, '23514', NULL, 'invalid rows are rejected'
);
SELECT * FROM finish(TRUE);
