\set VERBOSITY verbose
\set ON_ERROR_STOP on

CREATE DATABASE test;
\c test


SELECT version();
SELECT * FROM pg_available_extensions ORDER BY name;


CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;


-- https://github.com/pgadmin-org/pgagent
CREATE EXTENSION IF NOT EXISTS pgagent;

/* Create pgAgent job - https://karatejb.blogspot.com/2020/04/postgresql-pgagent-scheduling-agent.html */
DO $$
DECLARE
    jid integer;
    scid integer;
BEGIN
-- Creating a new job
INSERT INTO pgagent.pga_job(
    jobjclid, jobname, jobdesc, jobhostagent, jobenabled
) VALUES (
    1::integer, 'Routine Clean'::text, ''::text, ''::text, true
) RETURNING jobid INTO jid;

-- Steps
-- Inserting a step (jobid: NULL)
INSERT INTO pgagent.pga_jobstep (
    jstjobid, jstname, jstenabled, jstkind,
    jstconnstr, jstdbname, jstonerror,
    jstcode, jstdesc
) VALUES (
    jid, 'Clean_News'::text, true, 's'::character(1),
    'host=localhost port=5432 dbname=postgres connect_timeout=10 user=''postgres'''::text, ''::name, 'f'::character(1),
    'DELETE FROM public."News"'::text, ''::text
) ;

-- Schedules
-- Inserting a schedule
INSERT INTO pgagent.pga_schedule(
    jscjobid, jscname, jscdesc, jscenabled,
    jscstart, jscend,    jscminutes, jschours, jscweekdays, jscmonthdays, jscmonths
) VALUES (
    jid, 'Daily'::text, ''::text, true,
    '2020-04-24 06:14:44+00'::timestamp with time zone, '2020-04-30 05:51:17+00'::timestamp with time zone,
    -- Minutes
    ARRAY[false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,true,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false]::boolean[],
    -- Hours
    ARRAY[false,false,false,false,false,false,false,false,false,false,false,true,false,false,false,false,false,false,false,false,false,false,false,false]::boolean[],
    -- Week days
    ARRAY[false,false,false,false,false,false,false]::boolean[],
    -- Month days
    ARRAY[false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false]::boolean[],
    -- Months
    ARRAY[false,false,false,false,false,false,false,false,false,false,false,false]::boolean[]
) RETURNING jscid INTO scid;
END
$$;

SELECT * from pgagent."pga_job";
SELECT * from pgagent."pga_jobstep";
SELECT * from pgagent."pga_schedule";

/* Delete pgAgent job - https://karatejb.blogspot.com/2020/04/postgresql-pgagent-scheduling-agent.html */
DO $$
DECLARE
    jname VARCHAR(50) :='Routine Clean';
    jid INTEGER;
BEGIN

SELECT "jobid" INTO jid from pgagent."pga_job"
WHERE "jobname"=jname;

DELETE FROM pgagent."pga_schedule"
WHERE "jscjobid"=jid;

DELETE FROM pgagent.pga_jobstep
WHERE "jstjobid"=jid;

DELETE FROM pgagent."pga_job"
WHERE "jobid"=jid;

END
$$;


-- https://github.com/MigOpsRepos/credcheck
\set ON_ERROR_STOP off

SET credcheck.username_min_length = 4;
CREATE USER abc WITH PASSWORD 'pass';

SET credcheck.password_min_special = 1;
CREATE USER abcd WITH PASSWORD 'pass';

SET credcheck.password_contain_username = on;
SET credcheck.password_ignore_case = on;
CREATE USER abcd$ WITH PASSWORD 'ABCD$xyz';

\set ON_ERROR_STOP on


-- https://github.com/citusdata/pg_cron
CREATE EXTENSION pg_cron;
SELECT cron.schedule('nightly-vacuum', '0 3 * * *', 'VACUUM');
SELECT cron.unschedule('nightly-vacuum');


-- https://github.com/postgis/postgis
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;
CREATE EXTENSION IF NOT EXISTS postgis_raster;
CREATE EXTENSION IF NOT EXISTS postgis_sfcgal;
CREATE EXTENSION IF NOT EXISTS address_standardizer;

SELECT PostGIS_Full_Version();


-- https://github.com/pgaudit/pgaudit
CREATE EXTENSION IF NOT EXISTS pgaudit;
SET pgaudit.log = 'all, -misc';
SET pgaudit.log_level = notice;

-- https://github.com/fmbiete/pgauditlogtofile
CREATE EXTENSION IF NOT EXISTS pgauditlogtofile;
SHOW pgaudit.log_directory;
SHOW pgaudit.log_filename;
SHOW pgaudit.log_rotation_age;


-- https://github.com/HypoPG/hypopg
CREATE EXTENSION IF NOT EXISTS hypopg;

CREATE TABLE hypo AS SELECT id, 'line ' || id AS val FROM generate_series(1,10000) id;
EXPLAIN SELECT * FROM hypo WHERE id = 1;

SELECT * FROM hypopg_create_index('CREATE INDEX ON hypo (id)');
EXPLAIN SELECT * FROM hypo WHERE id = 1;

DROP TABLE hypo;


-- https://github.com/powa-team/pg_qualstats
CREATE EXTENSION IF NOT EXISTS pg_qualstats;
SELECT * FROM pg_qualstats;


-- https://github.com/powa-team/pg_stat_kcache
CREATE EXTENSION IF NOT EXISTS pg_stat_kcache;
SELECT * FROM pg_stat_kcache();


-- https://github.com/rjuju/pg_track_settings
CREATE EXTENSION IF NOT EXISTS pg_track_settings;
SELECT pg_track_settings_snapshot();


-- https://github.com/postgrespro/pg_wait_sampling
CREATE EXTENSION IF NOT EXISTS pg_wait_sampling;
WITH t as (SELECT sum(0) FROM pg_wait_sampling_current)
	SELECT sum(0) FROM generate_series(1, 2), t;


-- https://github.com/powa-team/powa-archivist
CREATE EXTENSION IF NOT EXISTS powa;
SELECT * FROM powa_functions ORDER BY module, operation;


-- https://github.com/pgRouting/pgrouting
CREATE EXTENSION IF NOT EXISTS pgrouting CASCADE;

CREATE TABLE edge_table (
    id BIGSERIAL,
    dir character varying,
    source BIGINT,
    target BIGINT,
    cost FLOAT,
    reverse_cost FLOAT,
    capacity BIGINT,
    reverse_capacity BIGINT,
    category_id INTEGER,
    reverse_category_id INTEGER,
    x1 FLOAT,
    y1 FLOAT,
    x2 FLOAT,
    y2 FLOAT,
    the_geom geometry
);

INSERT INTO edge_table (
    category_id, reverse_category_id,
    cost, reverse_cost,
    capacity, reverse_capacity,
    x1, y1,
    x2, y2
) VALUES
	(3, 1,    1,  1,  80, 130,   2,   0,    2, 1),
	(3, 2,   -1,  1,  -1, 100,   2,   1,    3, 1),
	(2, 1,   -1,  1,  -1, 130,   3,   1,    4, 1),
	(2, 4,    1,  1, 100,  50,   2,   1,    2, 2),
	(1, 4,    1, -1, 130,  -1,   3,   1,    3, 2),
	(4, 2,    1,  1,  50, 100,   0,   2,    1, 2),
	(4, 1,    1,  1,  50, 130,   1,   2,    2, 2),
	(2, 1,    1,  1, 100, 130,   2,   2,    3, 2),
	(1, 3,    1,  1, 130,  80,   3,   2,    4, 2),
	(1, 4,    1,  1, 130,  50,   2,   2,    2, 3),
	(1, 2,    1, -1, 130,  -1,   3,   2,    3, 3),
	(2, 3,    1, -1, 100,  -1,   2,   3,    3, 3),
	(2, 4,    1, -1, 100,  -1,   3,   3,    4, 3),
	(3, 1,    1,  1,  80, 130,   2,   3,    2, 4),
	(3, 4,    1,  1,  80,  50,   4,   2,    4, 3),
	(3, 3,    1,  1,  80,  80,   4,   1,    4, 2),
	(1, 2,    1,  1, 130, 100,   0.5, 3.5,  1.999999999999,3.5),
	(4, 1,    1,  1,  50, 130,   3.5, 2.3,  3.5,4);

UPDATE edge_table
SET the_geom = st_makeline(st_point(x1,y1), st_point(x2,y2)),
	dir = CASE
		WHEN (cost>0 AND reverse_cost>0) THEN 'B'   -- both ways
		WHEN (cost>0 AND reverse_cost<0) THEN 'FT'  -- direction of the LINESSTRING
		WHEN (cost<0 AND reverse_cost>0) THEN 'TF'  -- reverse direction of the LINESTRING
		ELSE ''                                     -- unknown
	END;

SELECT pgr_createTopology('edge_table',0.001);

SELECT pgr_analyzegraph('edge_table', 0.001);
SELECT pgr_nodeNetwork('edge_table', 0.001);

DROP TABLE edge_table;


-- https://github.com/pramsey/pgsql-ogr-fdw
CREATE EXTENSION IF NOT EXISTS ogr_fdw;

CREATE TABLE apostles (
	fid integer primary key GENERATED ALWAYS AS IDENTITY,
	geom geometry(point, 4326),
	joined integer,
	name text,
	height numeric,
	born date,
	clock time,
	ts timestamp
);

INSERT INTO apostles (name, geom, joined, height, born, clock, ts) VALUES
	('Peter',          'SRID=4326;POINT(30.31 59.93)',   1, 1.6,  '1912-01-10', '10:10:01', '1912-01-10 10:10:01'),
	('Andrew',         'SRID=4326;POINT(-2.8 56.34)',    2, 1.8,  '1911-02-11', '10:10:02', '1911-02-11 10:10:02'),
	('James',          'SRID=4326;POINT(-79.23 42.1)',   3, 1.72, '1910-03-12', '10:10:03', '1910-03-12 10:10:03'),
	('John',           'SRID=4326;POINT(13.2 47.35)',    4, 1.45, '1909-04-01', '10:10:04', '1909-04-01 10:10:04'),
	('Philip',         'SRID=4326;POINT(-75.19 40.69)',  5, 1.65, '1908-05-02', '10:10:05', '1908-05-02 10:10:05'),
	('Bartholomew',    'SRID=4326;POINT(-62 18)',        6, 1.69, '1907-06-03', '10:10:06', '1907-06-03 10:10:06'),
	('Thomas',         'SRID=4326;POINT(-80.08 35.88)',  7, 1.68, '1906-07-04', '10:10:07', '1906-07-04 10:10:07'),
	('Matthew',        'SRID=4326;POINT(-73.67 20.94)',  8, 1.65, '1905-08-05', '10:10:08', '1905-08-05 10:10:08'),
	('James Alpheus',  'SRID=4326;POINT(-84.29 34.07)',  9, 1.78, '1904-09-06', '10:10:09', '1904-09-06 10:10:09'),
	('Thaddaeus',      'SRID=4326;POINT(79.13 10.78)',  10, 1.88, '1903-10-07', '10:10:10', '1903-10-07 10:10:10'),
	('Simon',          'SRID=4326;POINT(-85.97 41.75)', 11, 1.61, '1902-11-08', '10:10:11', '1902-11-08 10:10:11'),
	('Judas Iscariot', 'SRID=4326;POINT(35.7 32.4)',    12, 1.71, '1901-12-09', '10:10:12', '1901-12-09 10:10:12');

CREATE SERVER wraparound
	FOREIGN DATA WRAPPER ogr_fdw
	OPTIONS (datasource 'Pg:dbname=test user=postgres', format 'PostgreSQL');

CREATE FOREIGN TABLE apostles_fdw (
	fid integer,
	geom geometry(point, 4326),
	joined integer,
	name text,
	height numeric,
	born date,
	clock time,
	ts timestamp
) SERVER wraparound OPTIONS (layer 'apostles');

SELECT * FROM apostles_fdw;

DROP TABLE apostles;
DROP SERVER wraparound CASCADE;


-- https://github.com/EnterpriseDB/mysql_fdw
CREATE EXTENSION IF NOT EXISTS mysql_fdw;
CREATE SERVER mysql_server
	FOREIGN DATA WRAPPER mysql_fdw
	OPTIONS (host '127.0.0.1', port '3306');
CREATE FOREIGN TABLE mysql_table (
	id integer,
	title text
) SERVER mysql_server OPTIONS (dbname 'db', table_name 'the_table');
DROP SERVER mysql_server CASCADE;


-- https://github.com/laurenz/oracle_fdw
CREATE EXTENSION IF NOT EXISTS oracle_fdw;
CREATE SERVER oradb
	FOREIGN DATA WRAPPER oracle_fdw
	OPTIONS (dbserver '//dbserver.mydomain.com:1521/ORADB');
CREATE FOREIGN TABLE oratab (
	id integer OPTIONS (key 'true') NOT NULL,
	title text OPTIONS (strip_zeros 'true')
) SERVER oradb OPTIONS (schema 'ORAUSER', table 'ORATAB');
DROP SERVER oradb CASCADE;


-- https://github.com/pgspider/sqlite_fdw
CREATE EXTENSION IF NOT EXISTS sqlite_fdw;
CREATE SERVER sqlite_server
	FOREIGN DATA WRAPPER sqlite_fdw
	OPTIONS (database '/tmp/test.db');
CREATE FOREIGN TABLE sqlite_table(
	id integer OPTIONS (key 'true'),
	title text OPTIONS(column_name 'nm_title'),
	modified timestamp OPTIONS (column_type 'INT')
) SERVER sqlite_server OPTIONS (table 't1_sqlite');
DROP SERVER sqlite_server CASCADE;


-- https://github.com/tds-fdw/tds_fdw
CREATE EXTENSION IF NOT EXISTS tds_fdw;
CREATE SERVER mssql_svr
	FOREIGN DATA WRAPPER tds_fdw
	OPTIONS (servername '127.0.0.1', port '1433', database 'tds_fdw_test', tds_version '7.1');
CREATE FOREIGN TABLE mssql_table (
	id integer,
	title text OPTIONS (column_name 'nm_title')
) SERVER mssql_svr OPTIONS (schema_name 'dbo', table_name 'mytable', row_estimate_method 'showplan_all');
DROP SERVER mssql_svr CASCADE;


-- https://github.com/df7cb/pgsql-asn1oid
CREATE EXTENSION IF NOT EXISTS asn1oid;
SELECT '1.3.6.1.4.1'::asn1oid;


-- https://github.com/lacanoid/pgddl
CREATE EXTENSION ddlx SCHEMA pg_catalog;
SELECT ddlx_create(oid) FROM pg_database WHERE datname=current_database();


-- https://github.com/df7cb/pg_dirtyread
CREATE EXTENSION pg_dirtyread;


-- https://github.com/xocolatl/extra_window_functions
CREATE EXTENSION IF NOT EXISTS extra_window_functions;

CREATE TABLE things (
    part integer NOT NULL,
    ord integer NOT NULL,
    val integer
);

COPY things FROM stdin;
1	1	64664
1	2	8779
1	3	14005
1	4	57699
1	5	98842
1	6	88563
1	7	70453
1	8	82824
1	9	62453
2	1	\N
2	2	51714
2	3	17096
2	4	41605
2	5	15366
2	6	87359
2	7	98990
2	8	34982
2	9	3343
3	1	21903
3	2	24605
3	3	6242
3	4	24947
3	5	79535
3	6	66903
3	7	42269
3	8	31143
3	9	\N
4	1	\N
4	2	49723
4	3	23958
4	4	80796
4	5	\N
4	6	41066
4	7	72991
4	8	33734
4	9	\N
5	1	\N
5	2	\N
5	3	\N
5	4	\N
5	5	\N
5	6	\N
5	7	\N
5	8	\N
5	9	\N
\.

/* FLIP_FLOP */
SELECT part, ord, val,
	flip_flop(val % 2 = 0) OVER w AS flip_flop_1,
	flip_flop(val % 2 = 0, val % 2 = 1) OVER w AS flip_flop_2
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

/* LAG */
SELECT part, ord, val,
	lag(val) OVER w AS lag,
	lag_ignore_nulls(val) OVER w AS lag_in,
	lag_ignore_nulls(val, 2) OVER w AS lag_in_off,
	lag_ignore_nulls(val, 2, -9999999) OVER w AS lag_in_off_d
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

/* LEAD */
SELECT part, ord, val,
	lead(val) OVER w AS lead,
	lead_ignore_nulls(val) OVER w AS lead_in,
	lead_ignore_nulls(val, 2) OVER w AS lead_in_off,
	lead_ignore_nulls(val, 2, 9999999) OVER w AS lead_in_off_d
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

/* FIRST_VALUE */
SELECT part, ord, val,
	first_value(val) OVER w AS fv,
	first_value_ignore_nulls(val) OVER w AS fv_in,
	first_value_ignore_nulls(val, 9999999) OVER w AS fv_in_d
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

/* LAST_VALUE */
SELECT part, ord, val,
	last_value(val) OVER w AS lv,
	last_value_ignore_nulls(val) OVER w AS lv_in,
	last_value_ignore_nulls(val, -9999999) OVER w AS lv_in_d
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

/* NTH_VALUE */
SELECT part, ord, val,
	nth_value(val, 3) OVER w AS nth,
	nth_value_ignore_nulls(val, 3) OVER w AS nth_in
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

SELECT part, ord, val,
	nth_value(val, 3) OVER w AS nth,
	nth_value_from_last(val, 3) OVER w AS nth_fl
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

SELECT part, ord, val,
	nth_value_from_last(val, 3) OVER w AS nth_fl,
	nth_value_from_last_ignore_nulls(val, 3) OVER w AS nth_fl_in
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

DROP TABLE things;


-- https://github.com/wulczer/first_last_agg
CREATE EXTENSION IF NOT EXISTS first_last_agg;
SELECT last(x order by y) FROM (VALUES (1, 3), (2, 1), (3, 2)) AS v(x, y);
SELECT first(x order by y) FROM (VALUES (1, 3), (2, 1), (3, 2)) AS v(x, y);


-- https://github.com/zachasme/h3-pg
CREATE EXTENSION h3;
CREATE EXTENSION h3_postgis;
SELECT h3_lat_lng_to_cell(ST_Point(-46.629055, -23.559378), 6);
SELECT ST_AsText(h3_cell_to_boundary_geometry('86a8100c7ffffff'));


-- https://github.com/citusdata/postgresql-hll
CREATE EXTENSION IF NOT EXISTS hll;
SELECT hll_empty();


-- https://github.com/dverite/icu_ext
CREATE EXTENSION IF NOT EXISTS icu_ext;
SELECT * FROM icu_locales_list() where name like 'pt%';


-- https://github.com/RhodiumToad/ip4r
CREATE EXTENSION IF NOT EXISTS ip4r;
SELECT ipaddress '255.255.255.255' / 31;
SELECT ipaddress 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff' / 127;


-- https://github.com/theirix/json_accessors
CREATE EXTENSION IF NOT EXISTS json_accessors;

select json_get_text('{"foo":"qq", "bar": true}', 'foo');
select json_get_boolean('{"foo":"qq", "bar": true}', 'bar');
select json_get_int('{"baz": 42, "boo": 42.424242}', 'baz');
select json_get_bigint('{"baz": 9223372036854, "boo": 42.424242}', 'baz');
select json_get_numeric('{"baz": 42, "boo": 42.424242}', 'boo');
select json_get_text('{"foo":"qq", "bar": true}', 'noneofthese') is null;
select json_get_text('{"foo":null, "bar": true}', 'foo') is null;
select json_get_timestamp('{"foo":"qq", "bar": "2009-12-01 01:23:45"}', 'bar');

select json_array_to_text_array('["foo", "bar"]');
select json_array_to_boolean_array('[true, false]');
select json_array_to_int_array('[42, 43]');
select json_array_to_bigint_array('[42, 9223372036854]');
select json_array_to_numeric_array('[42.4242,43.4343]');
select json_array_to_timestamp_array('["2009-12-01 01:23:45", "2012-12-01 01:23:45"]');
select json_get_text_array('{"foo":"qq", "bar": ["baz1", "baz2", "baz3"]}', 'bar');

select json_get_boolean_array('{"foo":"qq", "bar": [true, false]}', 'bar');
select json_get_int_array('{"foo":"qq", "bar": [42, 43]}', 'bar');
select json_get_bigint_array('{"foo":"qq", "bar": [42, 9223372036854]}', 'bar');
select json_get_numeric_array('{"foo":"qq", "bar": [42.4242,43.4343]}', 'bar');
select json_get_timestamp_array('{"foo":"qq", "bar": ["2009-12-01 01:23:45", "2012-12-01 01:23:45"]}', 'bar');

select json_get_object('{"foo":"qq", "bar": ["baz1", "baz2", "baz3"]}', 'foo');
select json_get_object('{"foo":"qq", "bar": ["baz1", "baz2", "baz3"]}', 'bar');
select json_get_object('{"foo":"qq", "bar": {"baz1": "baz2"}}', 'bar');
select json_array_to_object_array('[{"foo":42}, {"bar":[]}]');
select json_get_object_keys('{"foo":"qq", "bar": ["baz1", "baz2", "baz3"]}');


-- https://github.com/postgrespro/jsquery
CREATE EXTENSION IF NOT EXISTS jsquery;
SELECT
	'{"x": true}' @@ 'x IS boolean'::jsquery,
	'{"x": 0.1}' @@ 'x IS numeric'::jsquery,
	'{"a": {"b": 1}}' @@ 'a IS object'::jsquery,
	'{"a": ["xxx"]}' @@ 'a IS array AND a.#: IS string'::jsquery,
	'["xxx"]' @@ '$ IS array'::jsquery,
	'{"points": [{"x": 1, "y": 2}, {"x": 3.9, "y": 0.5}]}' @@ 'points.#:(x IS numeric AND y IS numeric)'::jsquery;


-- https://github.com/df7cb/postgresql-numeral
CREATE EXTENSION IF NOT EXISTS numeral;
SELECT 'thirty'::numeral + 'twelve'::numeral as sum;


-- https://github.com/orafce/orafce
CREATE EXTENSION IF NOT EXISTS orafce;
SELECT oracle.add_months(oracle.date'2021-05-31 10:12:12', 1);


-- https://github.com/theirix/parray_gin
CREATE EXTENSION IF NOT EXISTS parray_gin;

BEGIN;
CREATE TABLE parray_gin_test_table(id integer GENERATED ALWAYS AS IDENTITY, val text[]);
CREATE INDEX test_val_idx on parray_gin_test_table using gin (val parray_gin_ops);
ROLLBACK;


-- https://github.com/xocolatl/periods
CREATE EXTENSION IF NOT EXISTS periods;
SELECT * FROM periods.periods;


-- https://github.com/dverite/permuteseq
CREATE EXTENSION IF NOT EXISTS permuteseq;

CREATE SEQUENCE s MINVALUE -10000 MAXVALUE 15000;

\set secret_key 123456789012345

SELECT permute_nextval('s'::regclass, :secret_key) FROM generate_series(-10000, -9990);
SELECT reverse_permute('s'::regclass, -545, :secret_key);
SELECT range_encrypt_element(91919191919, 1e10::bigint, 1e11::bigint, :secret_key);
SELECT range_decrypt_element(83028080992, 1e10::bigint, 1e11::bigint, :secret_key);


-- https://github.com/enova/pg_fact_loader
CREATE EXTENSION IF NOT EXISTS pg_fact_loader;


-- https://github.com/ossc-db/pg_hint_plan
LOAD 'pg_hint_plan';

CREATE TEMP TABLE t1 AS
	SELECT 3*id AS id, random()
	FROM generate_series(1, 200000) AS t(id);
ALTER TABLE t1 ADD PRIMARY KEY (id);

CREATE TEMP TABLE t2 AS
	SELECT id, random()
	FROM generate_series(1, 600000) AS t(id);
ALTER TABLE t2 ADD PRIMARY KEY (id);

CREATE TEMP TABLE t3 AS
	SELECT 2*id AS id, random()
	FROM generate_series(1, 300000) AS t(id);
ALTER TABLE t3 ADD PRIMARY KEY (id);

ANALYZE t1, t2, t3;

EXPLAIN (costs off, timing off)
	SELECT *
	FROM t1
		JOIN t2 USING (id)
		JOIN t3 USING (id);

EXPLAIN (costs off, timing off)
	/*+ Leading((t3 (t2 t1))) NestLoop(t1 t2 t3) */
	SELECT *
	FROM t1
		JOIN t2 USING (id)
		JOIN t3 USING (id);

DROP TABLE t1;
DROP TABLE t2;
DROP TABLE t3;


-- https://github.com/klando/pgfincore
CREATE EXTENSION IF NOT EXISTS pgfincore;
SELECT * FROM pgsysconf_pretty();


-- https://github.com/enova/pgl_ddl_deploy
CREATE EXTENSION IF NOT EXISTS pgl_ddl_deploy;

--Setup permissions
SELECT pgl_ddl_deploy.add_role(oid) FROM pg_roles WHERE rolname in('app_owner', 'replication_role');

--Setup configs
INSERT INTO pgl_ddl_deploy.set_configs (set_name, include_schema_regex, lock_safe_deployment, allow_multi_statements)
VALUES ('default', '.*', true, true), ('insert_update', '.*happy.*', true, true);


-- https://github.com/2ndQuadrant/pglogical
CREATE EXTENSION IF NOT EXISTS pglogical;


-- https://github.com/enova/pglogical_ticker
CREATE EXTENSION IF NOT EXISTS pglogical_ticker;
SELECT pglogical_ticker.deploy_ticker_tables();


-- https://github.com/ohmu/pgmemcache
CREATE EXTENSION IF NOT EXISTS pgmemcache;


-- https://github.com/dvarrazzo/pgmp
CREATE EXTENSION IF NOT EXISTS pgmp;
SELECT 10.1::numeric::mpq;
SELECT 9223372036854775807::mpz;


-- https://github.com/petere/pgpcre
CREATE EXTENSION IF NOT EXISTS pgpcre;
SELECT 'foo' ~ pcre 'fo+';
SELECT pcre 'fo+' ~ 'foo';


-- https://github.com/pgq/pgq
CREATE EXTENSION IF NOT EXISTS pgq;
SELECT pgq.create_queue('testqueue1');

-- https://github.com/pgq/pgq-node
CREATE EXTENSION IF NOT EXISTS pgq_node;
SELECT * FROM pgq_node.get_queue_locations('testqueue1');

SELECT pgq.drop_queue('testqueue1');


-- https://github.com/postgrespro/pgsphere
CREATE EXTENSION IF NOT EXISTS pg_sphere;

SELECT set_sphere_output('DEG');
SELECT npoints( spoly '{(10d,0d),(10d,1d),(15d,0d),(5d,-5d)}');
SELECT area(spoly '{(0d,0d),(0d,90d),(90d,0d)}')/(4.0*pi());
SELECT '<(180d,-90d),1.0d>'::scircle ~ spoly '{(0d,-89d),(90d,-89d),(180d,-89d),(270d,-89d)}';

SELECT set_sphere_output('DMS');
SELECT 180.0*dist('<( 0h 2m 30s , 10d 0m 0s), 0.1d>'::scircle,'<( 0h 2m 30s , -10d 0m 0s),0.1d>'::scircle)/pi();
SELECT scircle('(0d,-90d)'::spoint);

SELECT set_sphere_output('RAD');
SELECT dist('( 0h 2m 30s , 95d 0m 0s)'::spoint,'( 12h 2m 30s , 85d 0m 0s)'::spoint);
SELECT long('(24h 2m 30s ,-85d 0m 0s)'::spoint);
SELECT lat('( 0h 2m 30s ,85d 0m 0s)'::spoint);
SELECT spoint(7.28318530717958623 , 0.00);


-- https://github.com/theory/pgtap
CREATE EXTENSION IF NOT EXISTS pgtap;
SELECT * FROM no_plan();
SELECT ok(TRUE);
SELECT * FROM finish();


-- https://github.com/sjstoelting/pgsql-tweaks
CREATE EXTENSION IF NOT EXISTS pgsql_tweaks;

SELECT is_date('2018-01-01'), is_date('2018-02-31'), is_date('01.01.2018', 'DD.MM.YYYY');
SELECT is_time('14:33:55.456574'), is_time('25:33:55.456574'), is_time('14.33.55,456574', 'HH24.MI.SS,US');
SELECT is_timestamp('2018-01-01 00:00:00'), is_timestamp('01.01.2018 00:00:00', 'DD.MM.YYYY HH24.MI.SS');
SELECT is_real('123.456'), is_real('123,456'), is_double_precision('123.456'), is_double_precision('123,456');
SELECT is_numeric('123'), is_numeric('1 2'), is_bigint('9876543210'), is_integer('98765'), is_smallint('321');
SELECT is_boolean('yes'), is_boolean('false'), is_boolean('NO'), is_boolean('TRUE'), is_boolean('1'), is_boolean('F');
SELECT is_json('{"review": {"date": "1970-12-30", "votes": 10, "rating": 5, "helpful_votes": 0}, "product": {"id": "1551803542", "group": "Book", "title": "Start and Run a Coffee Bar (Start & Run a)", "category": "Business & Investing", "sales_rank": 11611, "similar_ids": ["0471136174", "0910627312", "047112138X", "0786883561", "0201570483"], "subcategory": "General"}, "customer_id": "AE22YDHSBFYIP"}');
SELECT is_jsonb('{"review": {"date": "1970-12-30", "votes": 10, "rating": 5, "helpful_votes": 0}, "product": {"id": "1551803542", "group": "Book", "title": "Start and Run a Coffee Bar (Start & Run a)", "category": "Business & Investing", "sales_rank": 11611, "similar_ids": ["0471136174", "0910627312", "047112138X", "0786883561", "0201570483"], "subcategory": "General"}, "customer_id": "AE22YDHSBFYIP"}');
SELECT is_empty_b(''), is_empty_b(NULL), is_empty_b('NULL');
SELECT is_hex('a1b0'), is_hex('a1b0c3c3c3c4b5d3'), hex2bigint('a1b0');
SELECT sha256('test-string'::bytea);
SELECT pg_size_pretty(pg_schema_size('public'));
SELECT is_encoding('ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝ', 'LATIN1'), is_encoding('àáâãäåçèéêëìíîïñòóôõöùúûüýÿ', 'LATIN1', 'UTF8');
SELECT return_not_part_of_encoding('ağbƵcğeƵ', 'latin1');
SELECT to_unix_timestamp('2018-01-01 00:00:00+01');
SELECT array_trim(ARRAY['2018-11-11 11:00:00 MEZ',NULL,'2018-11-11 11:00:00 MEZ']::TIMESTAMP WITH TIME ZONE[], TRUE);


-- https://github.com/petere/pguint
CREATE EXTENSION uint;
CREATE TABLE uint_test (
    i1 int1,  -- signed 8-bit integer
	u1 uint1,  -- unsigned 8-bit integer
	u2 uint2,  -- unsigned 16-bit integer
	u4 uint4,  -- unsigned 32-bit integer
	u8 uint8  -- unsigned 64-bit integer
);
INSERT INTO uint_test VALUES (-128, 0, 0, 0, 0), (127, 255, 65535, 4294967295, 18446744073709551615);


-- https://github.com/pgvector/pgvector
CREATE EXTENSION vector;
CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3));
INSERT INTO items (embedding) VALUES ('[1,2,3]'), ('[4,5,6]');
SELECT * FROM items ORDER BY embedding <-> '[3,1,2]' LIMIT 5;


-- https://github.com/EnterpriseDB/pldebugger
CREATE EXTENSION IF NOT EXISTS pldbgapi;


-- https://github.com/okbob/plpgsql_check
CREATE EXTENSION IF NOT EXISTS plpgsql_check;

SELECT p.proname, tgrelid::regclass, cf.*
FROM pg_proc p
    JOIN pg_trigger t ON t.tgfoid = p.oid
    JOIN pg_language l ON p.prolang = l.oid
    JOIN pg_namespace n ON p.pronamespace = n.oid,
    LATERAL plpgsql_check_function(p.oid, t.tgrelid) cf
WHERE n.nspname = 'public' and l.lanname = 'plpgsql';


-- https://github.com/bigsql/plprofiler
CREATE EXTENSION IF NOT EXISTS plprofiler;


-- https://github.com/plproxy/plproxy
CREATE EXTENSION IF NOT EXISTS plproxy;


-- https://github.com/petere/plsh
CREATE EXTENSION IF NOT EXISTS plsh;
CREATE FUNCTION concat_plsh(text, text) RETURNS text AS '
#!/bin/sh
echo "$1$2"
' LANGUAGE plsh;
SELECT concat_plsh('It ', 'works!');


-- https://github.com/pgpointcloud/pointcloud
CREATE EXTENSION IF NOT EXISTS pointcloud;
CREATE EXTENSION IF NOT EXISTS pointcloud_postgis;

INSERT INTO pointcloud_formats (pcid, srid, schema) VALUES (1, 4326,
'<?xml version="1.0" encoding="UTF-8"?>
<pc:PointCloudSchema xmlns:pc="http://pointcloud.org/schemas/PC/1.1"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <pc:dimension>
    <pc:position>1</pc:position>
    <pc:size>4</pc:size>
    <pc:description>X coordinate as a long integer. You must use the
                    scale and offset information of the header to
                    determine the double value.</pc:description>
    <pc:name>X</pc:name>
    <pc:interpretation>int32_t</pc:interpretation>
    <pc:scale>0.01</pc:scale>
  </pc:dimension>
  <pc:dimension>
    <pc:position>2</pc:position>
    <pc:size>4</pc:size>
    <pc:description>Y coordinate as a long integer. You must use the
                    scale and offset information of the header to
                    determine the double value.</pc:description>
    <pc:name>Y</pc:name>
    <pc:interpretation>int32_t</pc:interpretation>
    <pc:scale>0.01</pc:scale>
  </pc:dimension>
  <pc:dimension>
    <pc:position>3</pc:position>
    <pc:size>4</pc:size>
    <pc:description>Z coordinate as a long integer. You must use the
                    scale and offset information of the header to
                    determine the double value.</pc:description>
    <pc:name>Z</pc:name>
    <pc:interpretation>int32_t</pc:interpretation>
    <pc:scale>0.01</pc:scale>
  </pc:dimension>
  <pc:dimension>
    <pc:position>4</pc:position>
    <pc:size>2</pc:size>
    <pc:description>The intensity value is the integer representation
                    of the pulse return magnitude. This value is optional
                    and system specific. However, it should always be
                    included if available.</pc:description>
    <pc:name>Intensity</pc:name>
    <pc:interpretation>uint16_t</pc:interpretation>
    <pc:scale>1</pc:scale>
  </pc:dimension>
  <pc:metadata>
    <Metadata name="compression">dimensional</Metadata>
  </pc:metadata>
</pc:PointCloudSchema>');

SELECT ST_AsText(PC_MakePoint(1, ARRAY[-127, 45, 124.0, 4.0])::geometry);


-- https://salsa.debian.org/postgresql/postgresql-debversion
CREATE EXTENSION IF NOT EXISTS debversion;

SELECT v::debversion
FROM unnest(ARRAY[
	'4.1.5-2',
	'4.0.2-1',
	'4.1.4-1',
	'4.1.5-1',
	'4.2.0-1',
	'4.1.4-2',
	'4.1.5-2.01',
	'4.1.99-a2-1',
	'5.2.1-2',
	'5.0.0-3',
	'5.1.98.2-2',
	'3.1.4-1',
	'5.2.3-1',
	'0:5.2.2-1',
	'0:5.2.4-1',
	'1:3.2.3-1'
]) AS v;


-- https://github.com/dimitri/prefix
CREATE EXTENSION IF NOT EXISTS prefix;
SELECT '123'::prefix_range @> '123456';


-- https://github.com/schmiddy/pg_prioritize
CREATE EXTENSION IF NOT EXISTS prioritize;
SELECT get_backend_priority(pg_backend_pid());


-- https://github.com/cybertec-postgresql/pg_permissions
CREATE EXTENSION pg_permissions;
SELECT * FROM database_permissions LIMIT 5;
SELECT * FROM schema_permissions LIMIT 5;
SELECT * FROM table_permissions LIMIT 5;
SELECT * FROM view_permissions LIMIT 5;
SELECT * FROM column_permissions LIMIT 5;
SELECT * FROM function_permissions LIMIT 5;
SELECT * FROM sequence_permissions LIMIT 5;


-- https://github.com/begriffs/pg_rational
CREATE EXTENSION IF NOT EXISTS pg_rational;
SELECT 0.263157894737::float::rational;


-- https://github.com/reorg/pg_repack
CREATE EXTENSION IF NOT EXISTS pg_repack;


-- https://github.com/ChenHuajun/pg_roaringbitmap
CREATE EXTENSION IF NOT EXISTS roaringbitmap;
SELECT '{ 1 ,  -2  , 555555 ,  -4  ,2147483647,-2147483648}'::roaringbitmap;
SET roaringbitmap.output_format='array';
SELECT '\x3a30000000000000'::roaringbitmap;
SELECT roaringbitmap('{1,-2,-3}') & roaringbitmap('{-3,-4,5}');
SELECT roaringbitmap('{1,2,3}') | roaringbitmap('{3,4,5}');
SELECT roaringbitmap('{1,2,3}') | 6;
SELECT 1 | roaringbitmap('{1,2,3}');
SELECT roaringbitmap('{}') # roaringbitmap('{3,4,5}');
SELECT roaringbitmap('{1,2,3}') - roaringbitmap('{}');
SELECT roaringbitmap('{-1,-2,3}') - -1;
SELECT roaringbitmap('{-2,-1,0,1,2,3,2147483647,-2147483648}') << 4294967296;
SELECT roaringbitmap('{-2,-1,0,1,2,3,2147483647,-2147483648}') >> -2;
SELECT roaringbitmap('{1,2,3}') @> roaringbitmap('{3,2}');
SELECT roaringbitmap('{1,2,3}') @> 1;
SELECT roaringbitmap('{1,-3}')  <@ roaringbitmap('{-3,1,1000}');
SELECT 6 <@ roaringbitmap('{}');
SELECT roaringbitmap('{1,2,3}') && roaringbitmap('{3,4,5}');
SELECT roaringbitmap('{}') = roaringbitmap('{}');
SELECT roaringbitmap('{1,2,3}') <> roaringbitmap('{3,1,2}');
SELECT rb_build('{1,-2,555555,-4,2147483647,-2147483648}'::int[]);
SELECT rb_to_array('{-1,2,555555,-4}'::roaringbitmap);
SELECT rb_is_empty('{}');
SELECT rb_cardinality('{1,10,100}');
SELECT rb_max('{1,10,100,2147483647,-2147483648,-1}');
SELECT rb_min('{1,10,100,2147483647,-2147483648,-1}');
SELECT rb_iterate('{1,10,100,2147483647,-2147483648,-1}');


-- https://github.com/cybertec-postgresql/pgfaceting
CREATE TABLE test_faceting(
	facet_name text,
	distinct_values integer,
	cardinality_sum integer
);

DO $$
BEGIN
	IF current_setting('server_version_num')::int >= 140000 THEN
		CREATE EXTENSION IF NOT EXISTS pgfaceting;  -- needs roaringbitmap

		CREATE TYPE mimetype AS ENUM (
			'application/pdf',
			'text/html',
			'image/jpeg',
			'image/png',
			'application/msword',
			'text/csv',
			'application/zip',
			'application/vnd.ms-powerpoint'
		);

		CREATE TABLE documents (
			id int4 primary key,
			created timestamptz not null,
			finished timestamptz,
			category_id int4,
			tags text[],
			type mimetype,
			size int8,
			title text
		);

		INSERT INTO documents (id, created, finished, category_id, tags, type, size, title) VALUES
			(1, '2010-01-01 00:00:42+02', '2010-01-01 09:45:29+02', 8, '{blue,burlywood,antiquewhite,olive}', 'application/pdf', 71205, 'Interracial marriage Science Research'),
			(2, '2010-01-01 00:00:37+02', '2010-01-01 03:55:08+02', 12, '{lightcoral,bisque,blue,"aqua blue","red purple",aqua}', 'text/html', 682069, 'Odour and trials helped to improve the country''s history through the public'),
			(3, '2010-01-01 00:00:33+02', '2010-01-02 18:29:15+02', 9, '{"mustard brown","very light pink"}', 'application/pdf', 143708, 'Have technical scale, ordinary, commonsense notions of absolute time and length independent of the'),
			(4, '2010-01-01 00:00:35+02', '2010-01-02 01:12:08+02', 24, '{orange,green,blue}', 'text/html', 280663, 'Database of (/ˈdɛnmɑːrk/; Danish: Danmark [ˈd̥ænmɑɡ̊]) is a spiral'),
			(5, '2010-01-01 00:01:06+02', '2010-01-01 23:18:56+02', 24, '{orange,chocolate}', 'image/jpeg', 111770, 'Passage to now resumed'),
			(6, '2010-01-01 00:01:05+02', '2010-01-01 10:25:29+02', 8, '{blue,aquamarine}', 'application/pdf', 110809, 'East. Mesopotamia, BCE – 480 BCE), when determining a value that'),
			(7, '2010-01-01 00:00:57+02', '2010-01-02 00:41:01+02', NULL, '{}', 'application/pdf', 230803, 'Bahía de It has also conquered 13 South American finds and another'),
			(8, '2010-01-01 00:01:11+02', '2010-01-01 14:22:11+02', 24, '{blue,burlywood,"dirt brown",orange,ivory,brown,green,olive,lightpink}', 'image/jpeg', 1304196, '15-fold: from the mid- to late-20th'),
			(9, '2010-01-01 00:01:47+02', '2010-01-01 09:59:57+02', 9, '{green,blue,orange}', 'application/pdf', 142410, 'Popular Western localized function model. Psychiatric interventions such as local businesses, but also'),
			(10, '2010-01-01 00:01:31+02', '2010-01-01 05:49:47+02', 24, '{green,lavender,blue,orange,red,darkslateblue}', 'text/html', 199703, 'Rapidly expanding Large Interior Form, 1953-54, Man Enters the Cosmos and Nuclear Energy.');

		PERFORM faceting.add_faceting_to_table(
			'documents',
			key => 'id',
			facets => array[
				faceting.datetrunc_facet('created', 'month'),
				faceting.datetrunc_facet('finished', 'month'),
				faceting.plain_facet('category_id'),
				faceting.plain_facet('type'),
				faceting.bucket_facet('size', buckets => array[0,1000,5000,10000,50000,100000,500000])
			]
		);

		INSERT INTO test_faceting
			SELECT facet_name, count(distinct facet_value), sum(cardinality)
			FROM faceting.count_results(
				'documents'::regclass,
				filters => array[row('category_id', 24)]::faceting.facet_filter[]
			)
			GROUP BY 1;
	END IF;
END $$;

SELECT * FROM test_faceting;
DROP TABLE test_faceting;


-- https://github.com/bigsmoke/pg_rowalesce
DO $$
BEGIN
	IF current_setting('server_version_num')::int >= 140000 THEN
		CREATE EXTENSION IF NOT EXISTS pg_rowalesce CASCADE;
		CALL test__pg_rowalesce();
	END IF;
END $$;


-- https://github.com/petropavel13/pg_rrule
CREATE EXTENSION pg_rrule;
SELECT get_freq('FREQ=WEEKLY;INTERVAL=1;WKST=MO;UNTIL=20200101T045102Z'::rrule);
SELECT get_byday('FREQ=WEEKLY;INTERVAL=1;WKST=MO;UNTIL=20200101T045102Z;BYDAY=MO,TH,SU'::rrule);
SELECT * FROM
	unnest(
		get_occurrences(
			'FREQ=WEEKLY;INTERVAL=1;WKST=MO;UNTIL=20200101T045102Z;BYDAY=SA;BYHOUR=10;BYMINUTE=51;BYSECOND=2'::rrule,
			'2019-12-07 10:51:02+00'::timestamp
		)
	);


-- https://github.com/segasai/q3c
CREATE EXTENSION q3c;
SELECT q3c_version();
SELECT q3c_ang2ipix(0, 0);


-- https://github.com/postgrespro/rum
CREATE EXTENSION IF NOT EXISTS rum;

CREATE TABLE test_rum(t text, a tsvector);

CREATE TRIGGER tsvectorupdate
BEFORE UPDATE OR INSERT ON test_rum
FOR EACH ROW EXECUTE PROCEDURE tsvector_update_trigger('a', 'pg_catalog.english', 't');

INSERT INTO test_rum(t) VALUES ('The situation is most beautiful');
INSERT INTO test_rum(t) VALUES ('It is a beautiful');
INSERT INTO test_rum(t) VALUES ('It looks like a beautiful place');

CREATE INDEX rumidx ON test_rum USING rum (a rum_tsvector_ops);

SELECT t, a <=> to_tsquery('english', 'beautiful | place') AS rank
FROM test_rum
WHERE a @@ to_tsquery('english', 'beautiful | place')
ORDER BY a <=> to_tsquery('english', 'beautiful | place');

DROP TABLE test_rum;


-- https://github.com/theory/pg-semver
CREATE EXTENSION IF NOT EXISTS semver;

SELECT v::semver
FROM unnest(ARRAY[
	'1.2.2',
	'0.2.2',
	'0.0.0',
	'0.1.999',
	'9999.9999999.823823',
	'1.0.0-beta1',
	'1.0.0-beta2',
	'1.0.0',
	'1.0.0-1',
	'1.0.0-alpha+d34dm34t',
	'1.0.0+d34dm34t',
	'20110204.0.0',
	'1.0.0-alpha.0a',
	'1.0.0+010',
	'1.0.0+alpha.010',
	'1.0.0-0AEF'
]) AS v;


-- https://github.com/pgaudit/set_user
CREATE EXTENSION set_user;

SELECT set_user('pg_monitor');
SELECT CURRENT_USER, SESSION_USER;

SELECT reset_user();
SELECT CURRENT_USER, SESSION_USER;


-- https://github.com/cybertec-postgresql/pg_show_plans
CREATE EXTENSION pg_show_plans;
SELECT * FROM pg_show_plans;


-- https://github.com/eulerto/pg_similarity
CREATE EXTENSION IF NOT EXISTS pg_similarity;

CREATE TABLE foo (a text);
CREATE TABLE bar (b text);

INSERT INTO foo
	VALUES('Euler'),('Oiler'),('Euler Taveira de Oliveira'),('Maria Taveira dos Santos'),('Carlos Santos Silva');
INSERT INTO bar
	VALUES('Euler T. de Oliveira'),('Euller'),('Oliveira, Euler Taveira'),('Sr. Oliveira');

SELECT a, b, cosine(a,b), jaro(a, b), euclidean(a, b), qgram(a, b), lev(a, b) FROM foo, bar;

DROP TABLE foo;
DROP TABLE bar;


-- https://github.com/cybertec-postgresql/pg_squeeze
CREATE EXTENSION pg_squeeze;
SELECT * FROM squeeze.tables;
SELECT squeeze.start_worker();
SELECT squeeze.stop_worker();


-- https://github.com/credativ/table_log
CREATE EXTENSION IF NOT EXISTS table_log;

BEGIN;

CREATE TABLE drop_test (
  id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  col1 text NOT NULL DEFAULT '',
  col2 text NOT NULL DEFAULT '',
  col3 text NOT NULL DEFAULT ''
);

SELECT table_log_init(5, 'public', 'drop_test', 'public', 'drop_test_log');

INSERT INTO drop_test (col1, col2, col3) VALUES ('a1', 'b1', 'c1');
SELECT * FROM drop_test;
SELECT * FROM drop_test_log;

ALTER TABLE drop_test DROP COLUMN col2;
ALTER TABLE drop_test_log DROP COLUMN col2;

INSERT INTO drop_test (col1, col3) VALUES ('a2', 'c2');
SELECT * FROM drop_test;
SELECT * FROM drop_test_log;

ROLLBACK;


-- https://github.com/tvondra/tdigest
CREATE EXTENSION IF NOT EXISTS tdigest;

CREATE TABLE t (a int, b int, c double precision);  -- table with some random source data

INSERT INTO t
	SELECT 10 * random(), 10 * random(), random()
	FROM generate_series(1, 100000);

CREATE TABLE p AS  -- table with pre-aggregated digests into table "p"
	SELECT a, b, tdigest(c, 100) AS d FROM t GROUP BY a, b;

-- summarize the data from "p" (compute the 95-th percentile)
SELECT a, tdigest_percentile(d, 0.95) FROM p GROUP BY a ORDER BY a;

DROP TABLE t;
DROP TABLE P;


-- https://github.com/credativ/toastinfo
CREATE EXTENSION IF NOT EXISTS toastinfo;

CREATE TABLE t (
    a text,
    b text
);

INSERT INTO t VALUES ('null', NULL);
INSERT INTO t VALUES ('default', 'default');

ALTER TABLE t ALTER COLUMN b SET STORAGE EXTERNAL;
INSERT INTO t VALUES ('external-10', 'external'); -- short inline varlena
INSERT INTO t VALUES ('external-200', repeat('x', 200)); -- long inline varlena, uncompressed
INSERT INTO t VALUES ('external-10000', repeat('x', 10000)); -- toasted varlena, uncompressed
INSERT INTO t VALUES ('external-1000000', repeat('x', 1000000)); -- toasted varlena, uncompressed

ALTER TABLE t ALTER COLUMN b SET STORAGE EXTENDED;
INSERT INTO t VALUES ('extended-10', 'extended'); -- short inline varlena
INSERT INTO t VALUES ('extended-200', repeat('x', 200)); -- long inline varlena, uncompressed
INSERT INTO t VALUES ('extended-10000', repeat('x', 10000)); -- long inline varlena, compressed (pglz)
INSERT INTO t VALUES ('extended-1000000', repeat('x', 1000000)); -- toasted varlena, compressed (pglz)

-- -- Postgres 14+ only
-- ALTER TABLE t ALTER COLUMN b SET COMPRESSION lz4;
-- INSERT INTO t VALUES ('extended-10000', repeat('x', 10000)); -- long inline varlena, compressed (lz4)
-- INSERT INTO t VALUES ('extended-1000000', repeat('x', 1000000)); -- toasted varlena, compressed (lz4)

SELECT a, length(b), pg_column_size(b), pg_toastinfo(b), pg_toastpointer(b) FROM t;

DROP TABLE t;


-- https://github.com/df7cb/postgresql-unit
CREATE EXTENSION IF NOT EXISTS unit;
SELECT '9.81 N'::unit / 'kg' AS gravity;


-- https://github.com/fboulnois/pg_uuidv7
CREATE EXTENSION IF NOT EXISTS pg_uuidv7;
SELECT uuid_generate_v7();


-- https://github.com/bigsmoke/pg_xenophile
DO $$
BEGIN
	IF current_setting('server_version_num')::int >= 140000 THEN
		CREATE EXTENSION IF NOT EXISTS pg_xenophile CASCADE;
		CALL xeno.test__l10n_table();
	END IF;
END $$;


-- https://github.com/hatarist/pg_xxhash
CREATE EXTENSION IF NOT EXISTS xxhash;

SELECT
	url,
	xxh32(url),
	xxh64(url),
	xxh3_64(url),
	xxh128(url),
	xxh32b(url),
	xxh64b(url),
	xxh3_64b(url),
	xxh128b(url)
FROM (SELECT 'https://example.com' AS url) x;


-- https://www.postgresql.org/docs/current/plperl.html
CREATE EXTENSION IF NOT EXISTS plperl;
CREATE OR REPLACE FUNCTION concat_array_elements(text[]) RETURNS TEXT AS $$
    my $arg = shift;
    my $result = "";
    return undef if (!defined $arg);

    # as an array reference
    for (@$arg) {
        $result .= $_;
    }

    # also works as a string
    $result .= $arg;

    return $result;
$$ LANGUAGE plperl;

SELECT concat_array_elements(ARRAY['PL','/','Perl']);


-- https://www.postgresql.org/docs/current/plpython.html
CREATE EXTENSION IF NOT EXISTS plpython3u;
CREATE EXTENSION IF NOT EXISTS hstore_plpython3u CASCADE;
CREATE EXTENSION IF NOT EXISTS ltree_plpython3u CASCADE;
CREATE EXTENSION IF NOT EXISTS jsonb_plpython3u;

CREATE OR REPLACE FUNCTION py_test() RETURNS text AS $$
	import sys

	with plpy.subtransaction():
		plpy.info('UPDATE tbl SET {} = {} WHERE key = {}'.format(
			plpy.quote_ident('Test Column'),
			plpy.quote_nullable(None),
			plpy.quote_literal('test value')
		))

	return 'Python version: {}'.format(sys.version)
$$ LANGUAGE plpython3u;
SELECT py_test();


-- https://github.com/timescale/timescaledb
CREATE EXTENSION IF NOT EXISTS timescaledb;

CREATE TABLE conditions (
	time timestamptz NOT NULL,
	location text NOT NULL,
	temperature double precision,
	humidity double precision
);

SELECT create_hypertable('conditions', 'time');

INSERT INTO conditions(time, location, temperature, humidity)
	VALUES (NOW(), 'office', 70.0, 50.0);

SELECT
	time_bucket('15 minutes', time) AS fifteen_min,
    location, COUNT(*),
    MAX(temperature) AS max_temp,
    MAX(humidity) AS max_hum
FROM conditions
WHERE time > NOW() - interval '3 hours'
GROUP BY fifteen_min, location
ORDER BY fifteen_min DESC, max_temp DESC;

DROP TABLE conditions;


-- https://github.com/MobilityDB/MobilityDB
DROP EXTENSION periods;  -- depends on btree_gist
DROP EXTENSION powa;  -- depends on btree_gist
DROP EXTENSION btree_gist;  -- both btree_gist and MobilityDB create an operator <-> with the same argument types
CREATE EXTENSION mobilitydb;

SELECT bigintset '{1,2,3}';
SELECT asText(floatset '{1.12345678, 2.123456789}', 6);
SELECT set(ARRAY [date '2000-01-01', '2000-01-02', '2000-01-03']);
SELECT set(ARRAY [timestamptz '2000-01-01', '2000-01-02', '2000-01-03']);
SELECT set(ARRAY[geometry 'Point(1 1)', 'Point(2 2)', 'Point(3 3)']);
SELECT memSize(dateset '{2000-01-01, 2000-01-02, 2000-01-03}');
SELECT span(tstzset '{2000-01-01, 2000-01-02, 2000-01-03}');
SELECT shiftScale(intset '{1}', 4, 4);

SELECT asText(floatspan '[1.12345678, 2.123456789]', 6);
SELECT span(timestamptz '2000-01-01', '2000-01-02');
SELECT span(timestamptz '2000-01-01', '2000-01-01', true, true);
SELECT range(datespan '[2000-01-01,2000-01-02)');
SELECT span(daterange'(2000-01-01,2000-01-03)');
SELECT span(date '2000-01-01');
SELECT date '2000-01-01'::datespan;
SELECT range(tstzspan '[2000-01-01,2000-01-02)');
SELECT span(tstzrange'(2000-01-01,2000-01-02)');
SELECT span(timestamptz '2000-01-01');
SELECT timestamptz '2000-01-01'::tstzspan;
SELECT intspan '[1,2]';
SELECT intspan '(1,2]';

SELECT bigintspanset '{[1,2),[3,4),[5,6)}';
SELECT spanset_cmp(datespanset '{[2000-01-01,2000-01-01]}', datespanset '{[2000-01-01,2000-01-02),[2000-01-03,2000-01-04),[2000-01-05,2000-01-06)}');
SELECT round(floatspanset '{[1.12345,2.12345),[3.12345,4.12345),[5.12345,6.12345)}', 2);
SELECT shift(intspanset '{[1,2),[3,4),[5,6)}', 2);
SELECT shiftScale(tstzspanset '{[2000-01-01,2000-01-02),(2000-01-03,2000-01-04),(2000-01-05,2000-01-06)}', '5 min', '1 hour');


SELECT * FROM pg_available_extensions ORDER BY name;


\c postgres

SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'test' AND pid <> pg_backend_pid();

DROP DATABASE test;
