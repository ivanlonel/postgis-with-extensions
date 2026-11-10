-- preload: pgautofailover
-- https://github.com/hapostgres/pg_auto_failover
-- The monitor's side: nodes register with it and are assigned their target state.
CREATE EXTENSION pgautofailover CASCADE;  -- requires btree_gist
CREATE TEMPORARY TABLE registered AS
SELECT * FROM pgautofailover.register_node('default', 'localhost', 9876, 'postgres');

SELECT plan(2);
SELECT is((SELECT count(*) FROM pgautofailover.node), 1::bigint, 'nodes register with the monitor');
SELECT is(
    (SELECT assigned_group_state::text FROM registered),
    'single',
    'a node alone in its group is meant to run on its own'
);
SELECT * FROM finish(TRUE);
