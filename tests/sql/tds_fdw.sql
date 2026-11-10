-- https://github.com/tds-fdw/tds_fdw
-- No SQL Server runs in the tests: FreeTDS must load and try to connect.
CREATE EXTENSION tds_fdw;

CREATE SERVER mssql_svr
FOREIGN DATA WRAPPER tds_fdw
OPTIONS (servername '127.0.0.1', port '1433', database 'tds_fdw_test', tds_version '7.1');
CREATE USER MAPPING FOR current_user SERVER mssql_svr OPTIONS (username 'sa', password 'secret');

CREATE FOREIGN TABLE mssql_table (
    id integer,
    title text OPTIONS (column_name 'nm_title')
) SERVER mssql_svr OPTIONS (schema_name 'dbo', table_name 'mytable', row_estimate_method 'showplan_all');

SELECT plan(1);
SELECT throws_like('SELECT * FROM mssql_table', '%Unable to connect%', 'FreeTDS tries to connect');
SELECT * FROM finish(TRUE);
