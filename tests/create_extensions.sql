\set VERBOSITY verbose
\set ON_ERROR_STOP on


-- https://github.com/citusdata/pg_cron
CREATE EXTENSION pg_cron;
SELECT cron.schedule('nightly-vacuum', '0 3 * * *', 'VACUUM');
SELECT cron.unschedule('nightly-vacuum');
DROP EXTENSION pg_cron;


CREATE DATABASE test;
\c test

SELECT * FROM pg_available_extensions;


-- https://github.com/postgis/postgis
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;


CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS btree_gist;
-- https://github.com/HypoPG/hypopg
CREATE EXTENSION IF NOT EXISTS hypopg;
-- https://github.com/powa-team/pg_qualstats
CREATE EXTENSION IF NOT EXISTS pg_qualstats;
-- https://github.com/powa-team/pg_stat_kcache
CREATE EXTENSION IF NOT EXISTS pg_stat_kcache;
-- https://github.com/rjuju/pg_track_settings
CREATE EXTENSION IF NOT EXISTS pg_track_settings;
-- https://github.com/postgrespro/pg_wait_sampling
CREATE EXTENSION IF NOT EXISTS pg_wait_sampling;
-- https://github.com/powa-team/powa-archivist
CREATE EXTENSION IF NOT EXISTS powa;


-- https://github.com/pramsey/pgsql-ogr-fdw
CREATE EXTENSION ogr_fdw;

-- https://github.com/EnterpriseDB/mysql_fdw
CREATE EXTENSION mysql_fdw;

-- https://github.com/laurenz/oracle_fdw
CREATE EXTENSION oracle_fdw;

-- https://github.com/pgspider/sqlite_fdw
CREATE EXTENSION sqlite_fdw;

-- https://github.com/tds-fdw/tds_fdw
CREATE EXTENSION tds_fdw;


-- https://github.com/df7cb/pgsql-asn1oid
CREATE EXTENSION asn1oid;
SELECT '1.3.6.1.4.1'::asn1oid;

-- https://github.com/df7cb/pg_dirtyread
CREATE EXTENSION pg_dirtyread;

-- https://github.com/xocolatl/extra_window_functions
CREATE EXTENSION extra_window_functions;

-- https://github.com/wulczer/first_last_agg
CREATE EXTENSION first_last_agg;

-- https://github.com/citusdata/postgresql-hll
CREATE EXTENSION hll;
SELECT hll_empty();

-- https://github.com/dverite/icu_ext
CREATE EXTENSION icu_ext;
SELECT * FROM icu_locales_list() where name like 'pt%';

-- https://github.com/RhodiumToad/ip4r
CREATE EXTENSION ip4r;
select ipaddress '255.255.255.255' / 31;
select ipaddress 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff' / 127;

-- https://github.com/postgrespro/jsquery
CREATE EXTENSION jsquery;

-- https://github.com/df7cb/postgresql-numeral
CREATE EXTENSION numeral;
SELECT 'thirty'::numeral + 'twelve'::numeral as sum;

-- https://github.com/orafce/orafce
CREATE EXTENSION orafce;

-- https://github.com/xocolatl/periods
CREATE EXTENSION periods;
SELECT * FROM periods.periods;

-- https://github.com/enova/pg_fact_loader
CREATE EXTENSION pg_fact_loader;

-- https://github.com/pgaudit/pgaudit
CREATE EXTENSION pgaudit;

-- https://github.com/klando/pgfincore
CREATE EXTENSION pgfincore;
SELECT * FROM pgsysconf_pretty();

-- https://github.com/enova/pgl_ddl_deploy
CREATE EXTENSION pgl_ddl_deploy;

-- https://github.com/2ndQuadrant/pglogical
CREATE EXTENSION pglogical;

-- https://github.com/enova/pglogical_ticker
CREATE EXTENSION pglogical_ticker;

-- https://github.com/ohmu/pgmemcache
CREATE EXTENSION pgmemcache;

-- https://github.com/dvarrazzo/pgmp
CREATE EXTENSION pgmp;
SELECT 10.1::numeric::mpq;
SELECT 9223372036854775807::mpz;

-- https://github.com/petere/pgpcre
CREATE EXTENSION pgpcre;
SELECT 'foo' ~ pcre 'fo+';
SELECT pcre 'fo+' ~ 'foo';

-- https://github.com/pgq/pgq
CREATE EXTENSION pgq;
SELECT pgq.create_queue('testqueue1');
SELECT pgq.drop_queue('testqueue1');

-- https://github.com/pgq/pgq-node
CREATE EXTENSION pgq_node;

-- https://github.com/pgRouting/pgrouting
CREATE EXTENSION pgrouting CASCADE;

-- https://github.com/theory/pgtap
CREATE EXTENSION pgtap;

-- https://github.com/EnterpriseDB/pldebugger
CREATE EXTENSION pldbgapi;

-- https://github.com/okbob/plpgsql_check
CREATE EXTENSION plpgsql_check;

-- https://github.com/petere/plsh
CREATE EXTENSION plsh;

-- https://github.com/pgpointcloud/pointcloud
CREATE EXTENSION pointcloud;
CREATE EXTENSION pointcloud_postgis;

-- https://github.com/dimitri/prefix
CREATE EXTENSION prefix;

-- https://github.com/begriffs/pg_rational
CREATE EXTENSION pg_rational;
SELECT 0.263157894737::float::rational;

-- https://github.com/reorg/pg_repack
CREATE EXTENSION pg_repack;

-- https://github.com/postgrespro/rum
CREATE EXTENSION rum;

-- https://github.com/eulerto/pg_similarity
CREATE EXTENSION pg_similarity;

-- https://github.com/tvondra/tdigest
CREATE EXTENSION tdigest;

-- https://github.com/credativ/toastinfo
CREATE EXTENSION toastinfo;

-- https://github.com/df7cb/postgresql-unit
CREATE EXTENSION unit;
SELECT '9.81 N'::unit / 'kg' AS gravity;

-- https://www.postgresql.org/docs/current/plpython.html
CREATE EXTENSION plpython3u;


\c postgres

DROP DATABASE TEST;
