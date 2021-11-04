\set VERBOSITY verbose
\set ON_ERROR_STOP on

CREATE DATABASE test;
\c test


SELECT * FROM pg_available_extensions;


-- https://github.com/citusdata/pg_cron
CREATE EXTENSION pg_cron;
SELECT cron.schedule('nightly-vacuum', '0 3 * * *', 'VACUUM');
SELECT cron.unschedule('nightly-vacuum');
DROP EXTENSION pg_cron;


-- https://github.com/postgis/postgis
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;


CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS btree_gist;


-- https://github.com/pgaudit/pgaudit
CREATE EXTENSION IF NOT EXISTS pgaudit;
SET pgaudit.log = 'all, -misc';
SET pgaudit.log_level = notice;


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


-- https://github.com/EnterpriseDB/mysql_fdw
CREATE EXTENSION IF NOT EXISTS mysql_fdw;
CREATE SERVER mysql_server
	FOREIGN DATA WRAPPER mysql_fdw
	OPTIONS (host '127.0.0.1', port '3306');
CREATE FOREIGN TABLE mysql_table (
	id integer,
	title text
) SERVER mysql_server OPTIONS (dbname 'db', table_name 'the_table');


-- https://github.com/laurenz/oracle_fdw
CREATE EXTENSION IF NOT EXISTS oracle_fdw;
CREATE SERVER oradb
	FOREIGN DATA WRAPPER oracle_fdw
	OPTIONS (dbserver '//dbserver.mydomain.com:1521/ORADB');
CREATE FOREIGN TABLE oratab (
	id integer OPTIONS (key 'true') NOT NULL,
	title text OPTIONS (strip_zeros 'true')
) SERVER oradb OPTIONS (schema 'ORAUSER', table 'ORATAB');


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


-- https://github.com/tds-fdw/tds_fdw
CREATE EXTENSION IF NOT EXISTS tds_fdw;
CREATE SERVER mssql_svr
	FOREIGN DATA WRAPPER tds_fdw
	OPTIONS (servername '127.0.0.1', port '1433', database 'tds_fdw_test', tds_version '7.1');
CREATE FOREIGN TABLE mssql_table (
	id integer,
	title text OPTIONS (column_name 'nm_title')
) SERVER mssql_svr OPTIONS (schema_name 'dbo', table_name 'mytable', row_estimate_method 'showplan_all');


-- https://github.com/df7cb/pgsql-asn1oid
CREATE EXTENSION IF NOT EXISTS asn1oid;
SELECT '1.3.6.1.4.1'::asn1oid;


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

-- https://github.com/xocolatl/periods
CREATE EXTENSION IF NOT EXISTS periods;
SELECT * FROM periods.periods;


-- https://github.com/enova/pg_fact_loader
CREATE EXTENSION IF NOT EXISTS pg_fact_loader;


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


-- https://github.com/theory/pgtap
CREATE EXTENSION IF NOT EXISTS pgtap;
SELECT * FROM no_plan();
SELECT ok(TRUE);
SELECT * FROM finish();


-- https://github.com/EnterpriseDB/pldebugger
CREATE EXTENSION IF NOT EXISTS pldbgapi;


-- https://github.com/pllua/pllua
CREATE EXTENSION IF NOT EXISTS plluau;
CREATE EXTENSION IF NOT EXISTS hstore_plluau CASCADE;

CREATE FUNCTION hello(person text) RETURNS text AS $$
	return "Hello, " .. person .. ", from Lua!"
$$ LANGUAGE plluau;
SELECT hello('Fred');


-- https://github.com/okbob/plpgsql_check
CREATE EXTENSION IF NOT EXISTS plpgsql_check;

SELECT p.proname, tgrelid::regclass, cf.*
FROM pg_proc p
    JOIN pg_trigger t ON t.tgfoid = p.oid
    JOIN pg_language l ON p.prolang = l.oid
    JOIN pg_namespace n ON p.pronamespace = n.oid,
    LATERAL plpgsql_check_function(p.oid, t.tgrelid) cf
WHERE n.nspname = 'public' and l.lanname = 'plpgsql';


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
SELECT ST_AsText(PC_MakePoint(1, ARRAY[-127, 45, 124.0, 4.0])::geometry);


-- https://github.com/dimitri/prefix
CREATE EXTENSION IF NOT EXISTS prefix;
SELECT '123'::prefix_range @> '123456';


-- https://github.com/schmiddy/pg_prioritize
CREATE EXTENSION IF NOT EXISTS prioritize;
SELECT get_backend_priority(pg_backend_pid());


-- https://github.com/begriffs/pg_rational
CREATE EXTENSION IF NOT EXISTS pg_rational;
SELECT 0.263157894737::float::rational;


-- https://github.com/reorg/pg_repack
CREATE EXTENSION IF NOT EXISTS pg_repack;


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

ALTER TABLE t ALTER COLUMN b SET COMPRESSION lz4;
INSERT INTO t VALUES ('extended-10000', repeat('x', 10000)); -- long inline varlena, compressed (lz4)
INSERT INTO t VALUES ('extended-1000000', repeat('x', 1000000)); -- toasted varlena, compressed (lz4)

SELECT a, length(b), pg_column_size(b), pg_toastinfo(b), pg_toastpointer(b) FROM t;

DROP TABLE t;


-- https://github.com/df7cb/postgresql-unit
CREATE EXTENSION IF NOT EXISTS unit;
SELECT '9.81 N'::unit / 'kg' AS gravity;


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

	return f'Python version: {sys.version}'
$$ LANGUAGE plpython3u;
SELECT py_test();


\c postgres

DROP DATABASE test;
