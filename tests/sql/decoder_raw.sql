-- https://github.com/michaelpq/pg_plugins/tree/main/decoder_raw
-- A logical decoding output plugin, not an extension: decode a change through a slot.
CREATE TABLE items (id integer PRIMARY KEY, name text);
SELECT 'created' FROM pg_create_logical_replication_slot('pwe_decoder_raw', 'decoder_raw');
INSERT INTO items VALUES (1, 'first');
CREATE TEMPORARY TABLE decoded AS
SELECT data FROM pg_logical_slot_get_changes('pwe_decoder_raw', NULL, NULL);
-- Dropped before the checks: a leftover slot would keep the database from being dropped.
SELECT pg_drop_replication_slot('pwe_decoder_raw');

SELECT plan(1);
SELECT matches(
    (SELECT string_agg(data, E'\n') FROM decoded),
    'INSERT INTO public\.items \(id, name\) VALUES \(1, ''first''\)',
    'changes come out as SQL statements'
);
SELECT * FROM finish(TRUE);
