-- preload: pgactive
-- https://github.com/aws/pgactive
-- Active-active replication between this database and a second one on the same server.
CREATE EXTENSION pgactive;
CREATE EXTENSION dblink;

CREATE TABLE items (id integer PRIMARY KEY, origin text NOT NULL);
INSERT INTO items VALUES (1, 'before the group');

CREATE DATABASE pwe_pgactive_peer;
CREATE FUNCTION on_peer(statement text) RETURNS text LANGUAGE sql AS $$
    SELECT r FROM dblink('dbname=pwe_pgactive_peer', statement) AS t (r text)
$$;
SELECT dblink_exec('dbname=pwe_pgactive_peer', 'CREATE EXTENSION pgactive');

-- Each node reaches both through pgactive_fdw servers and user mappings, in its own database.
CREATE FUNCTION node_servers(node1 text, node2 text) RETURNS text LANGUAGE sql AS $$
    SELECT format(
        'CREATE SERVER pwe_node1 FOREIGN DATA WRAPPER pgactive_fdw OPTIONS (dbname %L);'
        ' CREATE USER MAPPING FOR postgres SERVER pwe_node1;'
        ' CREATE SERVER pwe_node2 FOREIGN DATA WRAPPER pgactive_fdw OPTIONS (dbname %L);'
        ' CREATE USER MAPPING FOR postgres SERVER pwe_node2',
        node1,
        node2
    )
$$;
DO $$
BEGIN
    EXECUTE node_servers(current_database(), 'pwe_pgactive_peer');
END
$$;
SELECT dblink_exec('dbname=pwe_pgactive_peer', node_servers(current_database(), 'pwe_pgactive_peer'));

SELECT pgactive.pgactive_create_group(
    node_name := 'node1', node_dsn := 'user_mapping=postgres pgactive_foreign_server=pwe_node1'
);
SELECT pgactive.pgactive_wait_for_node_ready();
SELECT on_peer($$
    SELECT pgactive.pgactive_join_group(
        node_name := 'node2',
        node_dsn := 'user_mapping=postgres pgactive_foreign_server=pwe_node2',
        join_using_dsn := 'user_mapping=postgres pgactive_foreign_server=pwe_node1'
    )::text
$$);
SELECT on_peer('SELECT pgactive.pgactive_wait_for_node_ready()::text');

INSERT INTO items VALUES (2, 'node1');
SELECT on_peer($$INSERT INTO items VALUES (3, 'node2') RETURNING 'inserted'$$);

SELECT plan(3);
SELECT is(
    on_peer('SELECT origin FROM items WHERE id = 1'),
    'before the group',
    'joining copies the existing data'
);
SELECT ok(
    wait_until($$SELECT on_peer('SELECT count(*)::text FROM items WHERE id = 2') = '1'$$),
    'changes replicate to the peer'
);
SELECT ok(wait_until('SELECT EXISTS (SELECT FROM items WHERE id = 3)'), 'and back: both nodes take writes');

-- Take both nodes apart, so that no replication slot keeps either database from being dropped.
SELECT pgactive.pgactive_detach_nodes(ARRAY['node2']);
SELECT on_peer('SELECT pgactive.pgactive_remove(true)::text');
SELECT pgactive.pgactive_remove(TRUE);
SELECT pg_terminate_backend(active_pid) FROM pg_replication_slots
WHERE database IN (current_database(), 'pwe_pgactive_peer') AND active_pid IS NOT NULL;
SELECT wait_until(
    $$
        SELECT NOT EXISTS (
            SELECT FROM pg_replication_slots
            WHERE database IN (current_database(), 'pwe_pgactive_peer') AND active
        )
    $$
);
SELECT pg_drop_replication_slot(slot_name) FROM pg_replication_slots
WHERE database IN (current_database(), 'pwe_pgactive_peer');
DROP DATABASE pwe_pgactive_peer WITH (FORCE);
SELECT * FROM finish(TRUE);
