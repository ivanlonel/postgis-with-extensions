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

-- Reading the slot consumes it: keep what it returned.
CREATE TEMPORARY TABLE changes AS
SELECT string_agg(data, E'\n') AS json
FROM pg_logical_slot_get_changes('wal2json_test', NULL, NULL, 'pretty-print', '1', 'add-msg-prefixes', 'wal2json');
SELECT 'stop' FROM pg_drop_replication_slot('wal2json_test');

SELECT plan(5);
SELECT matches((SELECT json FROM changes), 'Backup and Restore', 'inserts are decoded');
SELECT matches((SELECT json FROM changes), '"kind": "delete"', 'deletes are decoded');
SELECT matches((SELECT json FROM changes), 'this message will be delivered', 'messages are decoded');
SELECT doesnt_match((SELECT json FROM changes), 'will be filtered', 'messages are filtered by prefix');
SELECT doesnt_match(
	(SELECT json FROM changes), 'Anta', 'updates of tables without a replica identity are left out'
);
SELECT * FROM finish(TRUE);
