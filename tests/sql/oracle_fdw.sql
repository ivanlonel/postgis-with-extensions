-- https://github.com/laurenz/oracle_fdw
-- No Oracle server runs in the tests: Oracle Instant Client must load and try to connect.
CREATE EXTENSION oracle_fdw;

CREATE SERVER oradb
FOREIGN DATA WRAPPER oracle_fdw
OPTIONS (dbserver '//127.0.0.1:1521/ORADB');
CREATE USER MAPPING FOR current_user SERVER oradb OPTIONS (user 'orauser', password 'secret');

CREATE FOREIGN TABLE oratab (
    id integer OPTIONS (key 'true') NOT NULL,
    title text OPTIONS (strip_zeros 'true')
) SERVER oradb OPTIONS (schema 'ORAUSER', table 'ORATAB');

SELECT plan(2);
SELECT matches(oracle_diag(), 'Oracle client \d', 'Oracle Instant Client is loaded');
-- oracle_fdw's own message leaves Oracle's error (ORA-nnnnn) to the detail.
SELECT matches(error_of('SELECT * FROM oratab'), 'ORA-\d+', 'the client tries to connect');
SELECT * FROM finish(TRUE);
