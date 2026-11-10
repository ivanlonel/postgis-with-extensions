-- preload: citus
-- https://github.com/citusdata/citus
-- A single-node cluster: the coordinator holds the shards too.
CREATE EXTENSION citus;
SELECT citus_set_coordinator_host('localhost', current_setting('port')::integer);
-- Should a shard query connect back to the coordinator, give Citus the test password.
INSERT INTO pg_dist_authinfo (nodeid, rolename, authinfo) VALUES (0, 'postgres', 'password=postgres');

CREATE TABLE events (id bigint PRIMARY KEY, kind text NOT NULL);
SELECT create_distributed_table('events', 'id', shard_count => 4);
INSERT INTO events
SELECT
    i,
    CASE WHEN i % 2 = 0 THEN 'even' ELSE 'odd' END
FROM generate_series(1, 1000) AS i;

SELECT plan(4);
SELECT is(
    (
        SELECT count(*) FROM pg_dist_shard
        WHERE logicalrelid = 'events'::regclass
    ),
    4::bigint,
    'tables are split into shards'
);
SELECT is(
    (
        SELECT count(*) FROM events
        WHERE kind = 'even'
    ),
    500::bigint,
    'queries span the shards'
);
SELECT is(
    (
        SELECT kind FROM events
        WHERE id = 7
    ),
    'odd',
    'single-row queries are routed to their shard'
);
SELECT matches(plan_of('SELECT count(*) FROM events'), 'Custom Scan \(Citus', 'the planner distributes queries');
SELECT * FROM finish(TRUE);
