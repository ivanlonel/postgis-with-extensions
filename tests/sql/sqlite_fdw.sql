-- pg: <=17
-- https://github.com/pgspider/sqlite_fdw
CREATE EXTENSION sqlite_fdw;

CREATE SERVER sqlite_server
FOREIGN DATA WRAPPER sqlite_fdw
OPTIONS (database '/tmp/test.db');

CREATE FOREIGN TABLE sqlite_table (
	id integer OPTIONS (key 'true'),
	title text OPTIONS (column_name 'nm_title'),
	modified timestamp OPTIONS (column_type 'INT')
) SERVER sqlite_server OPTIONS (table 't1_sqlite');
