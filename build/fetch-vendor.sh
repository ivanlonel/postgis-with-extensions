#!/usr/bin/env bash
# Download the pinned third-party .deb packages for PG_MAJOR into /debs.
#
# The versions come from the build arguments declared in the Dockerfile's vendor stage.
set -Eeuo pipefail

: "${PG_MAJOR:?}" "${VCHORD_VERSION:?}" "${PGVECTORSCALE_VERSION:?}"
: "${PG_GRAPHQL_VERSION:?}" "${PG_JSONSCHEMA_VERSION:?}" "${TIMESCALEDB_TOOLKIT_VERSION:?}"

# shellcheck source=/dev/null
. /etc/os-release

fetch() {
	curl --fail --silent --show-error --location --retry 3 --output "$1" "$2"
}

mkdir -p /debs
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

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
