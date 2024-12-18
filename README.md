#### PostgreSQL image based on [postgis/postgis](https://hub.docker.com/r/postgis/postgis), with quite a few added extensions

[![ivanlonel/postgis-with-extensions][docker-pulls-image]][docker-hub-url]
[![ivanlonel/postgis-with-extensions][github-last-commit-image]][github-url]
[![ivanlonel/postgis-with-extensions][github-workflow-status-image]][github-url]

Tag labels follow the pattern `X-Y.Z`, where `X` is the *major* Postgres version (starting from version 13) and `Y.Z` is the *major.minor* Postgis version.

The `latest` tag currently corresponds to `17-3.5`.

## Usage

In order to run a basic container capable of serving a Postgres database with all extensions below available:

```bash
docker run -e POSTGRES_PASSWORD=mysecretpassword -d ivanlonel/postgis-with-extensions
```

[Here](https://github.com/ivanlonel/postgis-with-extensions/tree/master/compose_example) is a sample docker-compose stack definition, which includes a [powa-web](https://hub.docker.com/r/powateam/powa-web) container and a [pgadmin](https://hub.docker.com/r/dpage/pgadmin4) container. The Postgres container is built from a Dockerfile that extends this image by running `localedef` in order to ensure Postgres will use the locale specified in docker-compose.yml.

For more detailed instructions about how to start and control your Postgres container, see the documentation for the `postgres` image [here](https://hub.docker.com/_/postgres/).

## Available extensions

- [age](https://github.com/apache/age)
- [asn1oid](https://github.com/df7cb/pgsql-asn1oid)
- [credcheck](https://github.com/MigOpsRepos/credcheck)
- [ddlx](https://github.com/lacanoid/pgddl)
- [extra_window_functions](https://github.com/xocolatl/extra_window_functions)
- [first_last_agg](https://github.com/wulczer/first_last_agg)
- [h3-pg](https://github.com/zachasme/h3-pg)
- [hll](https://github.com/citusdata/postgresql-hll)
- [hypopg](https://github.com/HypoPG/hypopg)
- [icu_ext](https://github.com/dverite/icu_ext)
- [ip4r](https://github.com/RhodiumToad/ip4r)
- [json_accessors](https://github.com/theirix/json_accessors)
- [jsquery](https://github.com/postgrespro/jsquery)
- [MobilityDB](https://github.com/MobilityDB/MobilityDB)
- [mysql_fdw](https://github.com/EnterpriseDB/mysql_fdw)
- [numeral](https://github.com/df7cb/postgresql-numeral)
- [ogr_fdw](https://github.com/pramsey/pgsql-ogr-fdw)
- [oracle_fdw](https://github.com/laurenz/oracle_fdw)
- [orafce](https://github.com/orafce/orafce)
- [parray_gin](https://github.com/theirix/parray_gin)
- [periods](https://github.com/xocolatl/periods)
- [permuteseq](https://github.com/dverite/permuteseq)
- [pg_cron](https://github.com/citusdata/pg_cron)
- [pg_dirtyread](https://github.com/df7cb/pg_dirtyread)
- [pg_fact_loader](https://github.com/enova/pg_fact_loader)
- [pg_hint_plan](https://github.com/ossc-db/pg_hint_plan)
- [pg_jobmon](https://github.com/omniti-labs/pg_jobmon)
- [pg_partman](https://github.com/pgpartman/pg_partman)
- [pg_permissions](https://github.com/cybertec-postgresql/pg_permissions)
- [pg_qualstats](https://github.com/powa-team/pg_qualstats)
- [pg_rational](https://github.com/begriffs/pg_rational)
- [pg_repack](https://github.com/reorg/pg_repack)
- [pg_roaringbitmap](https://github.com/ChenHuajun/pg_roaringbitmap)
- [pg_rowalesce](https://github.com/bigsmoke/pg_rowalesce)
- [pg_rrule](https://github.com/petropavel13/pg_rrule)
- [pg_show_plans](https://github.com/cybertec-postgresql/pg_show_plans)
- [pg_similarity](https://github.com/eulerto/pg_similarity)
- [pg_squeeze](https://github.com/cybertec-postgresql/pg_squeeze)
- [pg_stat_kcache](https://github.com/powa-team/pg_stat_kcache)
- [pg_track_settings](https://github.com/rjuju/pg_track_settings)
- [pg_uuidv7](https://github.com/fboulnois/pg_uuidv7)
- [pg_wait_sampling](https://github.com/postgrespro/pg_wait_sampling)
- [pg_xenophile](https://github.com/bigsmoke/pg_xenophile)
- [pg_xxhash](https://github.com/hatarist/pg_xxhash)
- [pgagent](https://github.com/pgadmin-org/pgagent)
- [pgaudit](https://github.com/pgaudit/pgaudit)
- [pgauditlogtofile](https://github.com/fmbiete/pgauditlogtofile)
- [pgfaceting](https://github.com/cybertec-postgresql/pgfaceting)
- [pgfincore](https://github.com/klando/pgfincore)
- [pgl_ddl_deploy](https://github.com/enova/pgl_ddl_deploy)
- [pglogical](https://github.com/2ndQuadrant/pglogical)
- [pglogical_ticker](https://github.com/enova/pglogical_ticker)
- [pgmemcache](https://github.com/ohmu/pgmemcache)
- [pgmp](https://github.com/dvarrazzo/pgmp)
- [pgmq](https://github.com/tembo-io/pgmq)
- [pgpcre](https://github.com/petere/pgpcre)
- [pgq](https://github.com/pgq/pgq)
- [pgq_node](https://github.com/pgq/pgq-node)
- [pgrouting](https://github.com/pgRouting/pgrouting)
- [pgsphere](https://github.com/postgrespro/pgsphere)
- [pgsql_tweaks](https://github.com/sjstoelting/pgsql-tweaks)
- [pgtap](https://github.com/theory/pgtap)
- [pguint](https://github.com/petere/pguint)
- [pgvector](https://github.com/pgvector/pgvector)
- [PL/Perl](https://www.postgresql.org/docs/current/plperl.html)
- [PL/Proxy](https://github.com/plproxy/plproxy)
- [PL/Python](https://www.postgresql.org/docs/current/plpython.html)
- [PL/sh](https://github.com/petere/plsh)
- [pldebugger (pldbgapi)](https://github.com/EnterpriseDB/pldebugger)
- [plpgsql_check](https://github.com/okbob/plpgsql_check)
- [plProfiler](https://github.com/bigsql/plprofiler)
- [pointcloud](https://github.com/pgpointcloud/pointcloud)
- [postgis](https://github.com/postgis/postgis)
- [postgresql-debversion](https://salsa.debian.org/postgresql/postgresql-debversion)
- [powa (archivist)](https://github.com/powa-team/powa-archivist)
- [prefix](https://github.com/dimitri/prefix)
- [prioritize](https://github.com/schmiddy/pg_prioritize)
- [q3c](https://github.com/segasai/q3c)
- [rum](https://github.com/postgrespro/rum)
- [semver](https://github.com/theory/pg-semver)
- [set_user](https://github.com/pgaudit/set_user)
- [sqlite_fdw](https://github.com/pgspider/sqlite_fdw)
- [table_log](https://github.com/credativ/table_log)
- [tdigest](https://github.com/tvondra/tdigest)
- [tds_fdw](https://github.com/tds-fdw/tds_fdw)
- [temporal_tables](https://github.com/arkhipov/temporal_tables)
- [timescaledb](https://github.com/timescale/timescaledb)
- [toastinfo](https://github.com/credativ/toastinfo)
- [unit](https://github.com/df7cb/postgresql-unit)
- [wal2json](https://github.com/eulerto/wal2json)

[docker-hub-url]: https://hub.docker.com/r/ivanlonel/postgis-with-extensions/
[github-url]: https://github.com/ivanlonel/postgis-with-extensions/
[docker-pulls-image]: https://img.shields.io/docker/pulls/ivanlonel/postgis-with-extensions.svg?style=flat
[github-last-commit-image]: https://img.shields.io/github/last-commit/ivanlonel/postgis-with-extensions.svg?style=flat
[github-workflow-status-image]: https://img.shields.io/github/actions/workflow/status/ivanlonel/postgis-with-extensions/docker-publish.yml?branch=master
