-- preload: pglogical
-- https://github.com/2ndQuadrant/pglogical
-- Replicate a table from this database to a second one on the same server.
CREATE EXTENSION pglogical;
CREATE EXTENSION dblink;

CREATE TABLE replicated (id integer PRIMARY KEY, v text);
INSERT INTO replicated VALUES (1, 'before the subscription');

SELECT pglogical.create_node(node_name := 'pwe_provider', dsn := format('dbname=%s', current_database()));
SELECT pglogical.replication_set_add_table('default', 'replicated', synchronize_data := TRUE);

-- The subscriber, set up through dblink (dblink_exec takes no statement returning rows).
CREATE DATABASE pwe_pglogical_subscriber;
CREATE FUNCTION on_subscriber(statement text) RETURNS text LANGUAGE sql AS $$
    SELECT r FROM dblink('dbname=pwe_pglogical_subscriber', statement) AS t (r text)
$$;
SELECT dblink_exec('dbname=pwe_pglogical_subscriber', 'CREATE EXTENSION pglogical');
SELECT dblink_exec('dbname=pwe_pglogical_subscriber', 'CREATE TABLE replicated (id integer PRIMARY KEY, v text)');
SELECT on_subscriber(
    $$SELECT pglogical.create_node(node_name := 'pwe_subscriber', dsn := 'dbname=pwe_pglogical_subscriber')::text$$
);
SELECT on_subscriber(
    format(
        $$SELECT pglogical.create_subscription(subscription_name := 'pwe_subscription', provider_dsn := %L)::text$$,
        format('dbname=%s', current_database())
    )
);

SELECT plan(2);
SELECT ok(
    wait_until($$SELECT on_subscriber('SELECT count(*)::text FROM replicated WHERE id = 1') = '1'$$),
    'existing rows are copied to the subscriber'
);
INSERT INTO replicated VALUES (2, 'after the subscription');
SELECT ok(
    wait_until($$SELECT on_subscriber('SELECT count(*)::text FROM replicated WHERE id = 2') = '1'$$),
    'new rows are replicated'
);

-- Clean up first: the subscription's slot would keep this database from being dropped.
SELECT on_subscriber($$SELECT pglogical.drop_subscription('pwe_subscription')::text$$);
DROP DATABASE pwe_pglogical_subscriber WITH (FORCE);
SELECT pglogical.drop_node('pwe_provider');
SELECT * FROM finish(TRUE);
