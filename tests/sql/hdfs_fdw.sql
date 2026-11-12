-- image: extended
-- https://github.com/EnterpriseDB/hdfs_fdw
-- No Hive server runs in the tests: the JVM and the wrapper's Java client must load and try to
-- connect. New clusters set hdfs_fdw.jvmpath; the classpath names the client the image ships in
-- the library directory (Hive's JDBC driver, which it would load next, isn't shipped).
CREATE EXTENSION hdfs_fdw;
SELECT set_config(
    'hdfs_fdw.classpath',
    (
        SELECT setting FROM pg_config
        WHERE name = 'PKGLIBDIR'
    ) || '/HiveJdbcClient-1.0.jar',
    FALSE
);

CREATE SERVER hdfs_server FOREIGN DATA WRAPPER hdfs_fdw OPTIONS (host '127.0.0.1', port '10000');
CREATE USER MAPPING FOR current_user SERVER hdfs_server;
CREATE FOREIGN TABLE weblogs (client_ip text) SERVER hdfs_server OPTIONS (dbname 'default', table_name 'weblogs');

SELECT plan(1);
SELECT throws_like(
    'SELECT * FROM weblogs',
    '%failed to initialize the connection%',
    'the Java client loads and tries to connect'
);
SELECT * FROM finish(TRUE);
