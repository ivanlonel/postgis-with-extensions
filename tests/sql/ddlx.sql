-- https://github.com/lacanoid/pgddl
CREATE EXTENSION ddlx SCHEMA pg_catalog;

SELECT plan(1);
SELECT matches(
	(
		SELECT ddlx_create(oid) FROM pg_database
		WHERE datname = current_database()
	),
	'CREATE DATABASE',
	'ddlx_create scripts the database'
);
SELECT * FROM finish(TRUE);
