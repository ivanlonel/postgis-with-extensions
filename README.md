# postgis-with-extensions

[![Docker pulls](https://img.shields.io/docker/pulls/ivanlonel/postgis-with-extensions.svg?style=flat)](https://hub.docker.com/r/ivanlonel/postgis-with-extensions/)
[![Last commit](https://img.shields.io/github/last-commit/ivanlonel/postgis-with-extensions.svg?style=flat)](https://github.com/ivanlonel/postgis-with-extensions/)
[![CI](https://img.shields.io/github/actions/workflow/status/ivanlonel/postgis-with-extensions/ci.yml?branch=master)](https://github.com/ivanlonel/postgis-with-extensions/actions/workflows/ci.yml)

PostgreSQL images based on [postgis/postgis](https://hub.docker.com/r/postgis/postgis), with more than a hundred
extra extensions. Published on Docker Hub (`ivanlonel/postgis-with-extensions`) and GHCR
(`ghcr.io/ivanlonel/postgis-with-extensions`).

## Tags

Tags follow the pattern `X-Y.Z`, where `X` is the PostgreSQL major version and `Y.Z` the PostGIS major.minor version.

- `14-3.7`, `15-3.7`, `16-3.7`, `17-3.7`, `18-3.7`: rebuilt every week from the matching postgis/postgis image, with
  the latest packages. `latest` is `18-3.7`.
- `14-3.6` to `18-3.6`: final release, no longer updated, like upstream's 3.6 images.

The images follow upstream's Debian tags (amd64 only): when postgis/postgis adds or drops a PostgreSQL or PostGIS
version, so does this repository.

> [!IMPORTANT]
> **From the 3.7 images on, nothing is preloaded by default.** Extensions that need `shared_preload_libraries` (such as
> TimescaleDB, pg_cron or PoWA) only work once enabled with
> [`SHARED_PRELOAD_LIBRARIES`](#enabling-libraries-that-need-preloading). `SHARED_PRELOAD_LIBRARIES=legacy` brings
> back the list earlier images preloaded on new clusters. Clusters created with earlier images keep their own
> configuration.

## Usage

```bash
docker run -e POSTGRES_PASSWORD=mysecretpassword -e SHARED_PRELOAD_LIBRARIES=all -d ivanlonel/postgis-with-extensions
```

[compose_example](https://github.com/ivanlonel/postgis-with-extensions/tree/master/compose_example) defines a stack
with a [powa-web](https://hub.docker.com/r/powateam/powa-web) and a [pgAdmin](https://hub.docker.com/r/dpage/pgadmin4)
container. It extends this image with `localedef`, so PostgreSQL uses the locale set in `compose.yaml`.

The [postgres image documentation](https://hub.docker.com/_/postgres/) explains how to configure and run the
container. From PostgreSQL 18 on, mount the data volume at `/var/lib/postgresql` (not `/var/lib/postgresql/data`).

### Enabling libraries that need preloading

`SHARED_PRELOAD_LIBRARIES` takes a comma-separated list of libraries (or the presets `all` and `legacy`) and is
applied on every start, so changing it and restarting the container is enough to enable or disable a library:

```bash
docker run -e POSTGRES_PASSWORD=mysecretpassword -e SHARED_PRELOAD_LIBRARIES=timescaledb,pg_cron,powa -d ivanlonel/postgis-with-extensions
```

- `all` preloads every library of the [extension table](#extensions)'s Preload column that the image ships for its
  PostgreSQL version, except DocumentDB's; `legacy` preloads the list the images preloaded by default before 3.7.
- DocumentDB is opt-in (`SHARED_PRELOAD_LIBRARIES=all,pg_documentdb` adds it): until `CREATE EXTENSION documentdb` has
  run in pg_cron's database, its background worker makes every `DROP DATABASE` wait up to 10 seconds.
- Libraries required by others come along: `powa` brings PoWA's statistics extensions, `pg_documentdb` brings
  `pg_documentdb_core`, `pg_documentdb_extended_rum` and `pg_cron`.
- The variable only adds libraries: those the cluster's own configuration preloads stay loaded. To remove one of those,
  edit the configuration, e.g. `ALTER SYSTEM SET shared_preload_libraries = '...'`, and restart.
- The settings a library relies on come along too (for instance `cron.database_name`), unless the configuration
  already sets them; options passed on the command line (`postgres -c name=value`) always win.
- An unknown library name stops the container with an error listing the valid ones. Any library installed in
  PostgreSQL's library directory is accepted, such as `auto_explain`.

### Environment variables

Besides the [postgres image variables](https://hub.docker.com/_/postgres/):

| Variable | Default | Description |
| -- | -- | -- |
| `SHARED_PRELOAD_LIBRARIES` |  | Libraries to add to `shared_preload_libraries` on every start (see above). |
| `PG_CRON_DB` | `POSTGRES_DB` | pg_cron's database (`cron.database_name`). |
| `PG_PARTMAN_DB` | `POSTGRES_DB` | pg_partman background worker's database (`pg_partman_bgw.dbname`). |
| `POWA_LOCAL_SNAPSHOT` | `YES` | `NO` sets PoWA up for remote snapshots: its statistics extensions are preloaded, not its own worker. |
| `POWA_EXTRA_SQL` |  | SQL to run in the `powa` database after setting it up. |

When PoWA is enabled on a new cluster, the image creates the `powa` database with PoWA's extensions, plus `hypopg` in
the `postgres` and `template1` databases. To set PoWA up on an existing cluster, enable `powa` and run
`docker exec <container> psql -U postgres -f /usr/local/src/install_all_powa_ext.sql`.

New clusters also get `wal_level = logical`, 10 WAL senders and replication slots, `max_locks_per_transaction = 128`
(as MobilityDB recommends) and trust the logical decoding plugins shipped in the image (`output_plugin_libraries`).

## Upgrading

### From the 3.6 images to 3.7

- Upgrade PostGIS in each database with `SELECT postgis_extensions_upgrade();`.
- PostGIS 3.7 no longer bundles `address_standardizer` and `postgis_tiger_geocoder`; this image installs their
  standalone packages, so databases using them keep working. Update them when convenient with
  `ALTER EXTENSION address_standardizer UPDATE;` (and likewise for the others).
- Nothing is preloaded by default on new clusters; existing clusters keep the libraries their configuration lists.
- The PoWA standby mode (`POWA_ROLE=STANDBY`) is gone: initialization now fails if it's set.

After an update that brings a new TimescaleDB version, run `ALTER EXTENSION timescaledb UPDATE;` as the first command
of a new session (`psql -X`) in each database that uses it.

### Security advisory: replication trusted from any host

Clusters created with images published before November 2026 trust replication connections from any IPv4 address,
without a password: the PoWA setup script appended `host replication all 0.0.0.0/0 trust` to `pg_hba.conf`. Anyone
reaching the server's port can copy the whole cluster with `pg_basebackup`. Remove that line and reload:

```bash
docker exec <container> bash -c 'sed -i "/^host\s\+replication\s\+all\s\+0\.0\.0\.0\/0\s\+trust/d" "$PGDATA/pg_hba.conf"'
docker exec <container> psql -U postgres -c 'SELECT pg_reload_conf()'
```

## Extensions

The extensions shipped with PostgreSQL itself (contrib) are available as well.

<!-- extensions:start -->

| Extension | PostgreSQL | Preload | Notes |
| -- | -- | -- | -- |
| [address_standardizer](https://github.com/postgis/address_standardizer) | all |  | Packaged separately from PostGIS since 3.7 |
| [age](https://github.com/apache/age) | all |  |  |
| [asn1oid](https://github.com/df7cb/pgsql-asn1oid) | all |  |  |
| [credcheck](https://github.com/HexaCluster/credcheck) | all | `credcheck` |  |
| [ddlx](https://github.com/lacanoid/pgddl) | all |  |  |
| [DocumentDB](https://github.com/documentdb/documentdb) | 15+ | `pg_documentdb` | SQL API only (no MongoDB wire-protocol gateway); `documentdb_distributed` needs Citus, which isn't included |
| [extra_window_functions](https://github.com/xocolatl/extra_window_functions) | all |  |  |
| [first_last_agg](https://github.com/wulczer/first_last_agg) | all |  |  |
| [h3-pg](https://github.com/postgis/h3-pg) | all |  |  |
| [hll](https://github.com/citusdata/postgresql-hll) | all |  |  |
| [http](https://github.com/pramsey/pgsql-http) | all |  |  |
| [hypopg](https://github.com/HypoPG/hypopg) | all |  |  |
| [icu_ext](https://github.com/dverite/icu_ext) | all |  |  |
| [ip4r](https://github.com/RhodiumToad/ip4r) | all |  |  |
| [json_accessors](https://github.com/theirix/json_accessors) | all |  |  |
| [jsquery](https://github.com/postgrespro/jsquery) | all |  |  |
| [MobilityDB](https://github.com/MobilityDB/MobilityDB) | all |  |  |
| [mongo_fdw](https://github.com/EnterpriseDB/mongo_fdw) | all |  |  |
| [mysql_fdw](https://github.com/EnterpriseDB/mysql_fdw) | all |  |  |
| [numeral](https://github.com/df7cb/postgresql-numeral) | all |  |  |
| [ogr_fdw](https://github.com/pramsey/pgsql-ogr-fdw) | all |  |  |
| [oracle_fdw](https://github.com/laurenz/oracle_fdw) | all |  |  |
| [orafce](https://github.com/orafce/orafce) | all |  |  |
| [parray_gin](https://github.com/theirix/parray_gin) | all |  |  |
| [periods](https://github.com/xocolatl/periods) | all |  |  |
| [permuteseq](https://github.com/dverite/permuteseq) | all |  |  |
| [pg_background](https://github.com/vibhorkum/pg_background) | all |  |  |
| [pg_bigm](https://github.com/pgbigm/pg_bigm) | all |  |  |
| [pg_cron](https://github.com/citusdata/pg_cron) | all | `pg_cron` |  |
| [pg_csv](https://github.com/PostgREST/pg_csv) | all |  |  |
| [pg_dirtyread](https://github.com/df7cb/pg_dirtyread) | all |  |  |
| [pg_fact_loader](https://salsa.debian.org/postgresql/pg-fact-loader) | up to 17 |  |  |
| [pg_graphql](https://github.com/supabase/pg_graphql) | all |  |  |
| [pg_hashids](https://github.com/iCyberon/pg_hashids) | all |  |  |
| [pg_hint_plan](https://github.com/ossc-db/pg_hint_plan) | all |  |  |
| [pg_ivm](https://github.com/sraoss/pg_ivm) | all | `pg_ivm` | Preloading is recommended, not required |
| [pg_jobmon](https://github.com/omniti-labs/pg_jobmon) | all |  |  |
| [pg_jsonschema](https://github.com/supabase/pg_jsonschema) | all |  |  |
| [pg_net](https://github.com/supabase/pg_net) | all | `pg_net` |  |
| [pg_partman](https://github.com/pgpartman/pg_partman) | all | `pg_partman_bgw` | Preload only for the background maintenance worker, which runs as `pg_partman_bgw.role` (default `partman_maintainer`, a role you create) |
| [pg_permissions](https://github.com/cybertec-postgresql/pg_permissions) | all |  |  |
| [pg_profile](https://github.com/zubkov-andrei/pg_profile) | all |  |  |
| [pg_pwhash](https://github.com/cybertec-postgresql/pg_pwhash) | all |  |  |
| [pg_qualstats](https://github.com/powa-team/pg_qualstats) | all | `pg_qualstats` |  |
| [pg_rational](https://github.com/begriffs/pg_rational) | all |  |  |
| [pg_repack](https://github.com/reorg/pg_repack) | all |  |  |
| [pg_rewrite](https://github.com/cybertec-postgresql/pg_rewrite) | all | `pg_rewrite` |  |
| [pg_roaringbitmap](https://github.com/ChenHuajun/pg_roaringbitmap) | all |  |  |
| [pg_rowalesce](https://github.com/bigsmoke/pg_rowalesce) | all |  |  |
| [pg_rrule](https://github.com/petropavel13/pg_rrule) | all |  |  |
| [pg_show_plans](https://github.com/cybertec-postgresql/pg_show_plans) | all | `pg_show_plans` | Off by default, as it [crashes inserts into TimescaleDB hypertables](https://github.com/timescale/timescaledb/pull/10417); enable with `pg_show_plans.is_enabled = on` |
| [pg_similarity](https://github.com/eulerto/pg_similarity) | all |  |  |
| [pg_squeeze](https://github.com/cybertec-postgresql/pg_squeeze) | all | `pg_squeeze` |  |
| [pg_stat_kcache](https://github.com/powa-team/pg_stat_kcache) | all | `pg_stat_kcache` |  |
| [pg_stat_log](https://github.com/fabriziomello/pg_stat_log) | 18+ | `pg_stat_log` |  |
| [pg_stat_monitor](https://github.com/percona/pg_stat_monitor) | all | `pg_stat_monitor` |  |
| [pg_statviz](https://github.com/vyruss/pg_statviz) | all |  |  |
| [pg_textsearch](https://github.com/timescale/pg_textsearch) | 17+ | `pg_textsearch` |  |
| [pg_tle](https://github.com/aws/pg_tle) | all | `pg_tle` |  |
| [pg_track_settings](https://github.com/rjuju/pg_track_settings) | all |  |  |
| [pg_uuidv7](https://github.com/fboulnois/pg_uuidv7) | all |  |  |
| [pg_wait_sampling](https://github.com/postgrespro/pg_wait_sampling) | all | `pg_wait_sampling` |  |
| [pg_xenophile](https://github.com/bigsmoke/pg_xenophile) | all |  |  |
| [pg_xxhash](https://github.com/hatarist/pg_xxhash) | all |  |  |
| [pgagent](https://github.com/pgadmin-org/pgagent) | all |  |  |
| [pgaudit](https://github.com/pgaudit/pgaudit) | all | `pgaudit` |  |
| [pgauditlogtofile](https://github.com/fmbiete/pgauditlogtofile) | all | `pgauditlogtofile` |  |
| [pgfaceting](https://github.com/cybertec-postgresql/pgfaceting) | all |  |  |
| [pgfincore](https://github.com/klando/pgfincore) | all |  |  |
| [pgl_ddl_deploy](https://github.com/enova/pgl_ddl_deploy) | up to 17 |  |  |
| [pglogical](https://github.com/2ndQuadrant/pglogical) | all | `pglogical` |  |
| [pglogical_ticker](https://github.com/enova/pglogical_ticker) | up to 17 | `pglogical_ticker` |  |
| [pgmemcache](https://github.com/ohmu/pgmemcache) | all | `pgmemcache` |  |
| [pgmp](https://github.com/dvarrazzo/pgmp) | all |  |  |
| [pgmq](https://github.com/pgmq/pgmq) | all |  |  |
| [pgnodemx](https://github.com/CrunchyData/pgnodemx) | all | `pgnodemx` |  |
| [pgpcre](https://github.com/petere/pgpcre) | all |  |  |
| [pgq](https://github.com/pgq/pgq) | all |  |  |
| [pgq_node](https://github.com/pgq/pgq-node) | all |  |  |
| [pgrouting](https://github.com/pgRouting/pgrouting) | all |  |  |
| [pgsentinel](https://github.com/pgsentinel/pgsentinel) | all | `pgsentinel` |  |
| [pgsphere](https://github.com/postgrespro/pgsphere) | all |  |  |
| [pgsql_tweaks](https://codeberg.org/pgsql_tweaks/pgsql_tweaks) | all |  |  |
| [pgtap](https://github.com/theory/pgtap) | all |  |  |
| [pgtt](https://github.com/darold/pgtt) | all |  |  |
| [pguint](https://github.com/petere/pguint) | all |  |  |
| [pgvector](https://github.com/pgvector/pgvector) | all |  |  |
| [pgvectorscale](https://github.com/timescale/pgvectorscale) | all |  |  |
| [PL/JS](https://github.com/plv8/pljs) | all |  |  |
| [PL/Lua](https://github.com/pllua/pllua) | all |  |  |
| [PL/Perl](https://www.postgresql.org/docs/current/plperl.html) | all |  |  |
| [PL/Proxy](https://github.com/plproxy/plproxy) | all |  |  |
| [PL/Python](https://www.postgresql.org/docs/current/plpython.html) | all |  |  |
| [PL/sh](https://github.com/petere/plsh) | all |  |  |
| [PL/Tcl](https://www.postgresql.org/docs/current/pltcl.html) | all |  |  |
| [pldebugger](https://github.com/EnterpriseDB/pldebugger) | all | `plugin_debugger` |  |
| [plpgsql_check](https://github.com/okbob/plpgsql_check) | all |  |  |
| [plProfiler](https://github.com/bigsql/plprofiler) | all | `plprofiler` | Collects nothing when `plugin_debugger` is loaded after it, as in the `legacy` and `all` presets: PL/pgSQL takes one plugin |
| [pointcloud](https://github.com/pgpointcloud/pointcloud) | all |  |  |
| [PostGIS](https://github.com/postgis/postgis) | all | `postgis-3` | From the base image; preloading it is optional |
| [postgis_tiger_geocoder](https://postgis.net/docs/Extras.html#Tiger_Geocoder) | all |  | Packaged separately from PostGIS since 3.7 |
| [postgresql-debversion](https://salsa.debian.org/postgresql/postgresql-debversion) | all |  |  |
| [PoWA (archivist)](https://github.com/powa-team/powa-archivist) | all | `powa` | Preloading it also preloads its statistics extensions and creates the `powa` database on new clusters |
| [prefix](https://github.com/dimitri/prefix) | all |  |  |
| [prioritize](https://github.com/schmiddy/pg_prioritize) | all |  |  |
| [q3c](https://github.com/segasai/q3c) | all |  |  |
| [rum](https://github.com/postgrespro/rum) | all |  |  |
| [semver](https://github.com/theory/pg-semver) | all |  |  |
| [set_user](https://github.com/pgaudit/set_user) | all | `set_user` |  |
| [sqlite_fdw](https://github.com/pgspider/sqlite_fdw) | up to 17 |  |  |
| [table_log](https://github.com/credativ/table_log) | all |  |  |
| [tdigest](https://github.com/tvondra/tdigest) | all |  |  |
| [tds_fdw](https://github.com/tds-fdw/tds_fdw) | all |  |  |
| [temporal_tables](https://github.com/arkhipov/temporal_tables) | all |  |  |
| [timescaledb](https://github.com/timescale/timescaledb) | all | `timescaledb` | Includes the Timescale License (TSL) features |
| [TimescaleDB Toolkit](https://github.com/timescale/timescaledb-toolkit) | 15+ |  | Timescale License (TSL) |
| [timestamp9](https://github.com/optiver/timestamp9) | all |  |  |
| [toastinfo](https://github.com/credativ/toastinfo) | all |  |  |
| [unit](https://github.com/df7cb/postgresql-unit) | all |  |  |
| [VectorChord](https://github.com/supervc-stack/VectorChord) | all | `vchord` | Dual-licensed AGPLv3 / ELv2 |
| [wal2json](https://github.com/eulerto/wal2json) | all |  | Logical decoding output plugin, not an extension |

<!-- extensions:end -->

## Development

The images are built with [Docker Bake](https://docs.docker.com/build/bake/) and tested with pytest and pgTAP:

```bash
docker buildx bake pg18 --load --set pg18.tags=postgis-with-extensions:dev   # or `docker buildx bake` for every major
uv run pytest --image postgis-with-extensions:dev
uv run prek run --all-files                                                 # linters and formatters
```

Set `PWE_TEST_LOGS` to a directory to keep the output of every server the tests start; CI uploads it as an artifact.

To add an extension:

- Install it: add its PGDG package to `build/apt-packages.txt`, or a build stage to the `Dockerfile` (pinned, with a
  `# renovate:` comment).
- Describe it in `extensions.toml` and run `uv run python -m scripts.render_readme` to update this table.
- If it needs preloading, register its library in `image/preload-libraries.txt`.
- Add `tests/sql/<extension>.sql`, a pgTAP script proving the extension works (known answers, not just loading).

CI builds and tests every PostgreSQL major on each pull request, and publishes from `master` and the weekly scheduled
run. Renovate keeps the pinned versions current.

## License

[MIT](LICENSE)
