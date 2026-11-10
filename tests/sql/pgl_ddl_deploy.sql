-- preload: pglogical
-- pg: <=17
-- https://github.com/enova/pgl_ddl_deploy
-- pgl_ddl_deploy needs pglogical but doesn't declare it, so CASCADE doesn't bring it.
CREATE EXTENSION pglogical;
CREATE EXTENSION pgl_ddl_deploy;

-- Replicate the DDL of schemas matching "happy" through pglogical's queue.
SELECT pglogical.create_node(node_name := 'pwe_ddl_provider', dsn := format('dbname=%s', current_database()));
INSERT INTO pgl_ddl_deploy.set_configs (set_name, include_schema_regex, lock_safe_deployment, allow_multi_statements)
VALUES ('default', '.*happy.*', TRUE, TRUE);

SELECT plan(3);
SELECT ok(pgl_ddl_deploy.deploy('default'), 'replication sets are deployed');

CREATE SCHEMA happy;
CREATE TABLE happy.customers (id integer PRIMARY KEY);
CREATE SCHEMA sad;
CREATE TABLE sad.customers (id integer PRIMARY KEY);

SELECT ok(
    EXISTS (
        SELECT FROM pgl_ddl_deploy.events
        WHERE ddl_sql_raw LIKE '%happy.customers%'
    ),
    'DDL in included schemas is captured'
);
SELECT ok(
    NOT EXISTS (
        SELECT FROM pgl_ddl_deploy.events
        WHERE ddl_sql_raw LIKE '%sad.customers%'
    ),
    'DDL elsewhere is ignored'
);
SELECT * FROM finish(TRUE);
