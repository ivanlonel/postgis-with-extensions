-- https://github.com/EnterpriseDB/mysql_fdw
CREATE EXTENSION mysql_fdw;

CREATE SERVER mysql_server
FOREIGN DATA WRAPPER mysql_fdw
OPTIONS (host '127.0.0.1', port '3306');

CREATE FOREIGN TABLE mysql_table (
	id integer,
	title text
) SERVER mysql_server OPTIONS (dbname 'db', table_name 'the_table');
