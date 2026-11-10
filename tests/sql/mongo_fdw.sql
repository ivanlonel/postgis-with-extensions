-- https://github.com/EnterpriseDB/mongo_fdw
CREATE EXTENSION mongo_fdw;

CREATE SERVER mongo_server
FOREIGN DATA WRAPPER mongo_fdw
OPTIONS (address '127.0.0.1', port '27017');

CREATE USER MAPPING FOR postgres SERVER mongo_server;

CREATE FOREIGN TABLE warehouse (
	_id name,
	warehouse_id integer,
	warehouse_name text
) SERVER mongo_server OPTIONS (database 'db', collection 'warehouse');
