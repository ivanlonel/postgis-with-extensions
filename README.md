#### PostgreSQL image based on [postgis/postgis](https://hub.docker.com/r/postgis/postgis), with quite a few added extensions

[![ivanlonel/postgis-with-extensions][docker-pulls-image]][docker-hub-url]
[![ivanlonel/postgis-with-extensions][github-last-commit-image]][github-url]
[![ivanlonel/postgis-with-extensions][github-workflow-status-image]][github-url]

Tag labels follow the pattern `X-Y.Z`, where `X` is the *major* Postgres version (starting from version 12) and `Y.Z` is the *major.minor* Postgis version.

The `latest` tag currently corresponds to `15-3.3`.

## Usage

In order to run a basic container capable of serving a Postgres database with all extensions below available:

```bash
docker run -e POSTGRES_PASSWORD=mysecretpassword -d ivanlonel/postgis-with-extensions
```

[Here](https://github.com/ivanlonel/postgis-with-extensions/tree/master/compose_example) is a sample docker-compose stack definition, which includes a [powa-web](https://hub.docker.com/r/powateam/powa-web) container and a [pgadmin](https://hub.docker.com/r/dpage/pgadmin4) container. The Postgres container is built from a Dockerfile that extends this image by running `localedef` in order to ensure Postgres will use the locale specified in docker-compose.yml.

For more detailed instructions about how to start and control your Postgres container, see the documentation for the `postgres` image [here](https://registry.hub.docker.com/_/postgres/).

## Available extensions

- [postgis](https://github.com/postgis/postgis)
- [asn1oid](https://github.com/df7cb/pgsql-asn1oid)
- [extra_window_functions](https://github.com/xocolatl/extra_window_functions)
- [first_last_agg](https://github.com/wulczer/first_last_agg)
- [hll](https://github.com/citusdata/postgresql-hll)
- [hypopg](https://github.com/HypoPG/hypopg)
- [icu_ext](https://github.com/dverite/icu_ext)
- [ip4r](https://github.com/RhodiumToad/ip4r)
- [jsquery](https://github.com/postgrespro/jsquery)
- [mysql_fdw](https://github.com/EnterpriseDB/mysql_fdw)
- [numeral](https://github.com/df7cb/postgresql-numeral)
- [ogr_fdw](https://github.com/pramsey/pgsql-ogr-fdw)
- [oracle_fdw](https://github.com/laurenz/oracle_fdw)
- [orafce](https://github.com/orafce/orafce)
- [periods](https://github.com/xocolatl/periods)
- [pgaudit](https://github.com/pgaudit/pgaudit)
- [pgfincore](https://github.com/klando/pgfincore)
- [pglogical](https://github.com/2ndQuadrant/pglogical)
- [pglogical_ticker](https://github.com/enova/pglogical_ticker)
- [pgl_ddl_deploy](https://github.com/enova/pgl_ddl_deploy)
- [pgmemcache](https://github.com/ohmu/pgmemcache)
- [pgmp](https://github.com/dvarrazzo/pgmp)
- [pgpcre](https://github.com/petere/pgpcre)
- [pgq](https://github.com/pgq/pgq)
- [pgq_node](https://github.com/pgq/pgq-node)
- [pgrouting](https://github.com/pgRouting/pgrouting)
- [pgtap](https://github.com/theory/pgtap)
- [pg_cron](https://github.com/citusdata/pg_cron)
- [pg_dirtyread](https://github.com/df7cb/pg_dirtyread)
- [pg_fact_loader](https://github.com/enova/pg_fact_loader)
- [pg_qualstats](https://github.com/powa-team/pg_qualstats)
- [pg_rational](https://github.com/begriffs/pg_rational)
- [pg_repack](https://github.com/reorg/pg_repack)
- [pg_similarity](https://github.com/eulerto/pg_similarity)
- [pg_stat_kcache](https://github.com/powa-team/pg_stat_kcache)
- [pg_track_settings](https://github.com/rjuju/pg_track_settings)
- [pg_wait_sampling](https://github.com/postgrespro/pg_wait_sampling)
- [pldebugger (pldbgapi)](https://github.com/EnterpriseDB/pldebugger)
- [pllua](https://github.com/pllua/pllua)
- [plpgsql_check](https://github.com/okbob/plpgsql_check)
- [plproxy](https://github.com/plproxy/plproxy)
- [plpython3](https://www.postgresql.org/docs/current/plpython.html)
- [plsh](https://github.com/petere/plsh)
- [pointcloud](https://github.com/pgpointcloud/pointcloud)
- [postgresql-debversion](https://salsa.debian.org/postgresql/postgresql-debversion)
- [powa (archivist)](https://github.com/powa-team/powa-archivist)
- [prefix](https://github.com/dimitri/prefix)
- [prioritize](https://github.com/schmiddy/pg_prioritize)
- [rum](https://github.com/postgrespro/rum)
- [semver](https://github.com/theory/pg-semver)
- [sqlite_fdw](https://github.com/pgspider/sqlite_fdw)
- [table_log](https://github.com/credativ/table_log)
- [tdigest](https://github.com/tvondra/tdigest)
- [tds_fdw](https://github.com/tds-fdw/tds_fdw)
- [timescaledb](https://github.com/timescale/timescaledb)
- [toastinfo](https://github.com/credativ/toastinfo)
- [unit](https://github.com/df7cb/postgresql-unit)

[docker-hub-url]: https://hub.docker.com/r/ivanlonel/postgis-with-extensions/
[github-url]: https://github.com/ivanlonel/postgis-with-extensions/
[docker-pulls-image]: https://img.shields.io/docker/pulls/ivanlonel/postgis-with-extensions.svg?style=flat
[github-last-commit-image]: https://img.shields.io/github/last-commit/ivanlonel/postgis-with-extensions.svg?style=flat
[github-workflow-status-image]: https://img.shields.io/github/workflow/status/ivanlonel/postgis-with-extensions/Create%20and%20publish%20a%20Docker%20image
