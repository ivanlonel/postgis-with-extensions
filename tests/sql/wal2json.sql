-- https://github.com/eulerto/wal2json
-- Needs wal_level = logical and wal2json in output_plugin_libraries, which new clusters get.
CREATE TABLE table2_with_pk (a serial, b varchar(30), c timestamp NOT NULL, PRIMARY KEY (a, c));
CREATE TABLE table2_without_pk (a serial, b numeric(5, 2), c text);

SELECT 'init' FROM pg_create_logical_replication_slot('wal2json_test', 'wal2json');

BEGIN;
INSERT INTO table2_with_pk (b, c) VALUES ('Backup and Restore', now());
INSERT INTO table2_with_pk (b, c) VALUES ('Tuning', now());
INSERT INTO table2_with_pk (b, c) VALUES ('Replication', now());
SELECT pg_logical_emit_message(TRUE, 'wal2json', 'this message will be delivered');
SELECT pg_logical_emit_message(TRUE, 'pgoutput', 'this message will be filtered');
DELETE FROM table2_with_pk
WHERE a < 3;
SELECT
	pg_logical_emit_message(
		FALSE, 'wal2json', 'this non-transactional message will be delivered even if you rollback the transaction'
	);

INSERT INTO table2_without_pk (b, c) VALUES (2.34, 'Tapir');
-- it is not added to stream because there isn't a pk or a replica identity
UPDATE table2_without_pk SET c = 'Anta'
WHERE c = 'Tapir';
COMMIT;

SELECT plan(1);
SELECT matches(
	(
		SELECT string_agg(data, E'\n')
		FROM pg_logical_slot_get_changes(
			'wal2json_test', NULL, NULL, 'pretty-print', '1', 'add-msg-prefixes', 'wal2json'
		)
	),
	'Backup and Restore',
	'wal2json decodes the changes'
);
SELECT * FROM finish(TRUE);

SELECT 'stop' FROM pg_drop_replication_slot('wal2json_test');
