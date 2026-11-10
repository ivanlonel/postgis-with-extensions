-- preload: pg_documentdb_core, pg_documentdb
-- pg: >=15
-- database: cron
-- https://github.com/documentdb/documentdb
BEGIN;
CREATE EXTENSION IF NOT EXISTS documentdb CASCADE;

SELECT documentdb_api.create_collection('smoke', 'patients');
SELECT documentdb_api.insert_one('smoke', 'patients', '{"patient_id": "P001", "name": "Alice"}');

SELECT plan(1);
SELECT is(
	(SELECT count(*) FROM documentdb_api.collection('smoke', 'patients')),
	1::bigint,
	'documents are stored'
);
SELECT * FROM finish(TRUE);
ROLLBACK;
