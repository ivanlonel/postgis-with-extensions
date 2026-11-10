-- https://github.com/EnterpriseDB/mysql_fdw
-- No MySQL server runs in the tests: the MySQL client library must load and try to connect.
CREATE EXTENSION mysql_fdw;

CREATE SERVER mysql_server
FOREIGN DATA WRAPPER mysql_fdw
OPTIONS (host '127.0.0.1', port '3306');
CREATE USER MAPPING FOR current_user SERVER mysql_server OPTIONS (username 'app', password 'secret');

CREATE FOREIGN TABLE mysql_table (
	id integer,
	title text
) SERVER mysql_server OPTIONS (dbname 'db', table_name 'the_table');

SELECT plan(2);
SELECT matches(mysql_fdw_version()::text, '^\d+$', 'the wrapper reports its version');
SELECT throws_like('SELECT * FROM mysql_table', '%failed to connect to MySQL%', 'the client library tries to connect');
SELECT * FROM finish(TRUE);
