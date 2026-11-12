#!/usr/bin/env bash
# Download the pinned third-party builds for PG_MAJOR: .deb packages to install into /debs, and
# extensions to copy as files into the /out staging tree.
#
# The versions come from the build arguments declared in the Dockerfile's vendor stage.
set -Eeuo pipefail

: "${VCHORD_VERSION:?}" "${PGVECTORSCALE_VERSION:?}"
: "${PG_GRAPHQL_VERSION:?}" "${PG_JSONSCHEMA_VERSION:?}" "${TIMESCALEDB_TOOLKIT_VERSION:?}"
: "${PGX_ULID_VERSION:?}" "${PLPRQL_VERSION:?}" "${PGDD_VERSION:?}"
: "${POSTGRES_PROTOBUF_VERSION:?}" "${PG_IDKIT_VERSION:?}"

# shellcheck source=vendor-lib.sh
. /usr/local/lib/postgis-with-extensions/vendor-lib.sh

mkdir -p /debs

fetch /debs/vchord.deb \
	"https://github.com/supervc-stack/VectorChord/releases/download/${VCHORD_VERSION}/postgresql-${PG_MAJOR}-vchord_${VCHORD_VERSION}-1_amd64.deb"

fetch /debs/pg_graphql.deb \
	"https://github.com/supabase/pg_graphql/releases/download/v${PG_GRAPHQL_VERSION}/pg_graphql-v${PG_GRAPHQL_VERSION}-pg${PG_MAJOR}-amd64-linux-gnu.deb"

fetch /debs/pg_jsonschema.deb \
	"https://github.com/supabase/pg_jsonschema/releases/download/v${PG_JSONSCHEMA_VERSION}/pg_jsonschema-v${PG_JSONSCHEMA_VERSION}-pg${PG_MAJOR}-amd64-linux-gnu.deb"

fetch "$workdir/pgvectorscale.zip" \
	"https://github.com/timescale/pgvectorscale/releases/download/${PGVECTORSCALE_VERSION}/pgvectorscale-${PGVECTORSCALE_VERSION}-pg${PG_MAJOR}-amd64.zip"
unzip -q -j "$workdir/pgvectorscale.zip" \
	"pgvectorscale-postgresql-${PG_MAJOR}_${PGVECTORSCALE_VERSION}-Linux_amd64.deb" -d "$workdir"
mv "$workdir/pgvectorscale-postgresql-${PG_MAJOR}_${PGVECTORSCALE_VERSION}-Linux_amd64.deb" /debs/pgvectorscale.deb

# TimescaleDB Toolkit supports PostgreSQL 15 and later.
if ((PG_MAJOR >= 15)); then
	fetch /debs/timescaledb-toolkit.deb \
		"https://packagecloud.io/timescale/timescaledb/debian/pool/${VERSION_CODENAME}/main/t/timescaledb-toolkit/timescaledb-toolkit-postgresql-${PG_MAJOR}_${TIMESCALEDB_TOOLKIT_VERSION}~debian${VERSION_ID}_amd64.deb"
fi

# pgx_ulid's package installs outside PostgreSQL's directories (its extension is named "ulid").
extract_deb pgx_ulid \
	"https://github.com/pksunkara/pgx_ulid/releases/download/v${PGX_ULID_VERSION}/pgx_ulid-v${PGX_ULID_VERSION}-pg${PG_MAJOR}-amd64-linux-gnu.deb"

extract_deb plprql \
	"https://github.com/kaspermarstal/plprql/releases/download/v${PLPRQL_VERSION}/plprql-${PLPRQL_VERSION}-postgresql-${PG_MAJOR}-debian-${VERSION_CODENAME}-amd64.deb"

# pgdd publishes Ubuntu builds, whose package also bundles other .deb files; noble's run on trixie.
extract_deb pgdd \
	"https://github.com/rustprooflabs/pgdd/releases/download/${PGDD_VERSION}/pgdd_${PGDD_VERSION}_noble_pg${PG_MAJOR}_amd64.deb"

# postgres-protobuf statically links protobuf and ships ~35 MiB of debug data: strip it. Its JIT
# bitcode isn't needed.
protobuf="postgres-protobuf-v${POSTGRES_PROTOBUF_VERSION}-linux-x86_64-for-pg${PG_MAJOR}"
fetch "$workdir/protobuf.tar.gz" \
	"https://github.com/mpartel/postgres-protobuf/releases/download/v${POSTGRES_PROTOBUF_VERSION}/${protobuf}.tar.gz"
tar -xf "$workdir/protobuf.tar.gz" -C "$workdir" # despite its name, not gzip-compressed
install -m 0755 "$workdir/$protobuf/lib/postgres_protobuf.so" "$libdir"
strip_libraries postgres_protobuf.so
install -m 0644 -t "$extdir" "$workdir/$protobuf"/extension/*

# pg_idkit publishes builds for PostgreSQL 15 and later.
if ((PG_MAJOR >= 15)); then
	fetch "$workdir/pg_idkit.tar.gz" \
		"https://github.com/VADOSWARE/pg_idkit/releases/download/v${PG_IDKIT_VERSION}/pg_idkit-${PG_IDKIT_VERSION}-pg${PG_MAJOR}-gnu.tar.gz"
	mkdir "$workdir/pg_idkit"
	tar -xf "$workdir/pg_idkit.tar.gz" -C "$workdir/pg_idkit"
	install_extension_files "$workdir/pg_idkit"
fi
