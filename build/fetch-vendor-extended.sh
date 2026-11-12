#!/usr/bin/env bash
# Download the pinned third-party builds the extended images add for PG_MAJOR, and copy their
# extension files into the /out staging tree, their libraries stripped of debug information (most
# of their size as published).
#
# The versions come from the build arguments declared in the Dockerfile's vendor-extended stage.
set -Eeuo pipefail

: "${PG_SEARCH_VERSION:?}" "${PG_DUCKDB_VERSION:?}" "${WRAPPERS_VERSION:?}"

# shellcheck source=vendor-lib.sh
. /usr/local/lib/postgis-with-extensions/vendor-lib.sh

# ParadeDB publishes pg_search for PostgreSQL 15 and later. Its runtime dependency, libopenblas0,
# is in apt-packages-extended.txt.
if ((PG_MAJOR >= 15)); then
	extract_deb pg_search \
		"https://github.com/paradedb/paradedb/releases/download/v${PG_SEARCH_VERSION}/postgresql-${PG_MAJOR}-pg-search_${PG_SEARCH_VERSION}-1PARADEDB-${VERSION_CODENAME}_amd64.deb"
	strip_libraries pg_search.so
fi

fetch "$workdir/pg_duckdb.tar.gz" \
	"https://github.com/duckdb/pg_duckdb/releases/download/v${PG_DUCKDB_VERSION}/pg_duckdb-pg${PG_MAJOR}-linux-x86_64.tar.gz"
mkdir "$workdir/pg_duckdb"
tar -xf "$workdir/pg_duckdb.tar.gz" -C "$workdir/pg_duckdb"
install_extension_files "$workdir/pg_duckdb"
strip_libraries pg_duckdb.so

# Supabase's package installs outside PostgreSQL's directories. Its library is named after its
# version, and a database's functions reference the version it was created with or last updated
# to: the older names its upgrade scripts start from link to the shipped library, so those
# databases keep working until ALTER EXTENSION wrappers UPDATE.
extract_deb wrappers \
	"https://github.com/supabase/wrappers/releases/download/v${WRAPPERS_VERSION}/wrappers-v${WRAPPERS_VERSION}-pg${PG_MAJOR}-amd64-linux-gnu.deb"
strip_libraries "wrappers-${WRAPPERS_VERSION}.so"
shopt -s nullglob
for script in "$extdir"/wrappers--*--*.sql; do
	from="${script##*/wrappers--}"
	from="${from%%--*}"
	if [[ ! -e "$libdir/wrappers-$from.so" ]]; then
		ln -s "wrappers-${WRAPPERS_VERSION}.so" "$libdir/wrappers-$from.so"
	fi
done
