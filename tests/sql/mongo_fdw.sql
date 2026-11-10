-- https://github.com/EnterpriseDB/mongo_fdw
-- No MongoDB server runs in the tests: the MongoDB C driver must load and try to connect.
CREATE EXTENSION mongo_fdw;

CREATE SERVER mongo_server
FOREIGN DATA WRAPPER mongo_fdw
OPTIONS (address '127.0.0.1', port '27017');

CREATE USER MAPPING FOR current_user SERVER mongo_server;

CREATE FOREIGN TABLE warehouse (
	_id name,
	warehouse_id integer,
	warehouse_name text
) SERVER mongo_server OPTIONS (database 'db', collection 'warehouse');

SELECT plan(2);
SELECT cmp_ok(mongo_fdw_version(), '>', 0, 'the wrapper reports its version');
SELECT throws_ok('SELECT * FROM warehouse', NULL, NULL, 'the driver tries to connect');
SELECT * FROM finish(TRUE);
