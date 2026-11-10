-- preload: pg_documentdb
-- pg: >=15
-- database: cron
-- https://github.com/documentdb/documentdb
-- DocumentDB does part of its work over a connection of its own, which only sees committed state,
-- so the extension is created outside the test transaction.
CREATE EXTENSION IF NOT EXISTS documentdb CASCADE;
CREATE EXTENSION IF NOT EXISTS documentdb_extended_rum;

SELECT documentdb_api.create_collection('smoke', 'patients');
SELECT documentdb_api.insert_one('smoke', 'patients', '{"patient_id": "P001", "name": "Alice", "age": 30}');
SELECT documentdb_api.insert_one('smoke', 'patients', '{"patient_id": "P002", "name": "Bob", "age": 45}');
SELECT documentdb_api.insert_one('smoke', 'patients', '{"patient_id": "P003", "name": "Carol", "age": 45}');

SELECT plan(5);
SELECT is(
	(SELECT count(*) FROM documentdb_api.collection('smoke', 'patients')),
	3::bigint,
	'documents are stored'
);
SELECT is(
	(
		SELECT count(*) FROM documentdb_api_catalog.bson_aggregation_find(
			'smoke', '{"find": "patients", "filter": {"age": {"$gt": 40}}}'
		)
	),
	2::bigint,
	'find filters documents'
);
SELECT is(
	(
		SELECT count(*) FROM documentdb_api_catalog.bson_aggregation_pipeline(
			'smoke', '{"aggregate": "patients", "pipeline": [{"$group": {"_id": "$age"}}], "cursor": {}}'
		)
	),
	2::bigint,
	'aggregation pipelines group documents'
);

SELECT documentdb_api.update(
	'smoke', '{"update": "patients", "updates": [{"q": {"patient_id": "P001"}, "u": {"$set": {"age": 31}}}]}'
);
SELECT is(
	(
		SELECT count(*) FROM documentdb_api_catalog.bson_aggregation_find(
			'smoke', '{"find": "patients", "filter": {"age": 31}}'
		)
	),
	1::bigint,
	'documents are updated'
);

SELECT documentdb_api.delete(
	'smoke', '{"delete": "patients", "deletes": [{"q": {"patient_id": "P002"}, "limit": 1}]}'
);
SELECT is(
	(SELECT count(*) FROM documentdb_api.collection('smoke', 'patients')),
	2::bigint,
	'documents are deleted'
);
SELECT * FROM finish(TRUE);
