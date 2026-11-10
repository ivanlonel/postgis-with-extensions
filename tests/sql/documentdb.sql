-- preload: pg_documentdb
-- pg: >=15
-- database: cron
-- https://github.com/documentdb/documentdb
-- DocumentDB does part of its work over a connection of its own, which only sees committed state,
-- so the extension is created outside the test transaction. Its collection functions must be in
-- the FROM clause of the statement being planned: results_eq() runs each query on its own.
CREATE EXTENSION IF NOT EXISTS documentdb CASCADE;
CREATE EXTENSION IF NOT EXISTS documentdb_extended_rum;

SELECT documentdb_api.create_collection('smoke', 'patients');
SELECT documentdb_api.insert_one('smoke', 'patients', '{"patient_id": "P001", "name": "Alice", "age": 30}');
SELECT documentdb_api.insert_one('smoke', 'patients', '{"patient_id": "P002", "name": "Bob", "age": 45}');
SELECT documentdb_api.insert_one('smoke', 'patients', '{"patient_id": "P003", "name": "Carol", "age": 45}');

SELECT plan(5);
SELECT results_eq(
	$$SELECT count(*) FROM documentdb_api.collection('smoke', 'patients')$$,
	$$VALUES (3::bigint)$$,
	'documents are stored'
);
SELECT results_eq(
	$$
		SELECT count(*) FROM documentdb_api_catalog.bson_aggregation_find(
			'smoke', '{"find": "patients", "filter": {"age": {"$gt": 40}}}'
		)
	$$,
	$$VALUES (2::bigint)$$,
	'find filters documents'
);
SELECT results_eq(
	$$
		SELECT count(*) FROM documentdb_api_catalog.bson_aggregation_pipeline(
			'smoke', '{"aggregate": "patients", "pipeline": [{"$group": {"_id": "$age"}}], "cursor": {}}'
		)
	$$,
	$$VALUES (2::bigint)$$,
	'aggregation pipelines group documents'
);

SELECT documentdb_api.update(
	'smoke', '{"update": "patients", "updates": [{"q": {"patient_id": "P001"}, "u": {"$set": {"age": 31}}}]}'
);
SELECT results_eq(
	$$
		SELECT count(*) FROM documentdb_api_catalog.bson_aggregation_find(
			'smoke', '{"find": "patients", "filter": {"age": 31}}'
		)
	$$,
	$$VALUES (1::bigint)$$,
	'documents are updated'
);

SELECT documentdb_api.delete(
	'smoke', '{"delete": "patients", "deletes": [{"q": {"patient_id": "P002"}, "limit": 1}]}'
);
SELECT results_eq(
	$$SELECT count(*) FROM documentdb_api.collection('smoke', 'patients')$$,
	$$VALUES (2::bigint)$$,
	'documents are deleted'
);
SELECT * FROM finish(TRUE);
