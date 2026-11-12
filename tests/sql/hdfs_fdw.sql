-- image: extended
-- https://github.com/EnterpriseDB/hdfs_fdw
-- No Hive server runs in the tests: the JVM and the wrapper's Java client must load and try to
-- connect. The library starts the JVM as it loads, with the client on hdfs_fdw.classpath: new
-- clusters set that and hdfs_fdw.jvmpath (Hive's JDBC driver, which the client loads next, isn't
-- shipped).
CREATE EXTENSION hdfs_fdw;

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
