-- https://github.com/cybertec-postgresql/pg_permissions
CREATE EXTENSION pg_permissions;

SELECT * FROM database_permissions LIMIT 5;
SELECT * FROM schema_permissions LIMIT 5;
SELECT * FROM table_permissions LIMIT 5;
SELECT * FROM view_permissions LIMIT 5;
SELECT * FROM column_permissions LIMIT 5;
SELECT * FROM function_permissions LIMIT 5;
SELECT * FROM sequence_permissions LIMIT 5;
