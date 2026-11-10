-- https://github.com/tds-fdw/tds_fdw
CREATE EXTENSION tds_fdw;

CREATE SERVER mssql_svr
FOREIGN DATA WRAPPER tds_fdw
OPTIONS (servername '127.0.0.1', port '1433', database 'tds_fdw_test', tds_version '7.1');

CREATE FOREIGN TABLE mssql_table (
	id integer,
	title text OPTIONS (column_name 'nm_title')
) SERVER mssql_svr OPTIONS (schema_name 'dbo', table_name 'mytable', row_estimate_method 'showplan_all');
