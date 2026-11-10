-- preload: pglogical
-- pg: <=17
-- https://github.com/enova/pgl_ddl_deploy
CREATE EXTENSION pgl_ddl_deploy CASCADE;  -- requires pglogical

SELECT pgl_ddl_deploy.add_role(oid) FROM pg_roles
WHERE rolname IN ('app_owner', 'replication_role');

INSERT INTO pgl_ddl_deploy.set_configs (set_name, include_schema_regex, lock_safe_deployment, allow_multi_statements)
VALUES ('default', '.*', TRUE, TRUE), ('insert_update', '.*happy.*', TRUE, TRUE);
