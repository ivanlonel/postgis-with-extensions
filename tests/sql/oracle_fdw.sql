-- https://github.com/laurenz/oracle_fdw
CREATE EXTENSION oracle_fdw;

CREATE SERVER oradb
FOREIGN DATA WRAPPER oracle_fdw
OPTIONS (dbserver '//dbserver.mydomain.com:1521/ORADB');

CREATE FOREIGN TABLE oratab (
	id integer OPTIONS (key 'true') NOT NULL,
	title text OPTIONS (strip_zeros 'true')
) SERVER oradb OPTIONS (schema 'ORAUSER', table 'ORATAB');
