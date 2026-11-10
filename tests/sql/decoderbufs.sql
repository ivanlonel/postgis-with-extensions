-- https://github.com/debezium/postgres-decoderbufs
-- A logical decoding output plugin, not an extension: decode a change through a slot into
-- Protocol Buffers messages (Debezium's format).
CREATE TABLE items (id integer PRIMARY KEY, name text);
SELECT 'created' FROM pg_create_logical_replication_slot('pwe_decoderbufs', 'decoderbufs');
INSERT INTO items VALUES (1, 'first');
CREATE TEMPORARY TABLE decoded AS
SELECT data FROM pg_logical_slot_get_binary_changes('pwe_decoderbufs', NULL, NULL);
-- Dropped before the checks: a leftover slot would keep the database from being dropped.
SELECT pg_drop_replication_slot('pwe_decoderbufs');

SELECT plan(2);
SELECT ok(
    EXISTS (
        SELECT FROM decoded
        WHERE position(convert_to('public.items', 'UTF8') IN data) > 0
    ),
    'messages name the changed table'
);
SELECT ok(
    EXISTS (
        SELECT FROM decoded
        WHERE position(convert_to('first', 'UTF8') IN data) > 0
    ),
    'and carry the new values'
);
SELECT * FROM finish(TRUE);
