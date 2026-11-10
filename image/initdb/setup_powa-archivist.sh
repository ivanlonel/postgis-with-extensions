#!/usr/bin/env bash
# Create the PoWA repository database when a new cluster is initialized, if PoWA is enabled.
#
# Adapted from powa-podman's setup_powa-archivist.sh (https://github.com/powa-team/powa-podman),
# keeping only the primary setup. Unlike that script, it neither edits pg_hba.conf (it used to
# trust replication connections from any IPv4 address) nor restarts the server: the entrypoint
# wrapper already starts the initialization server with the requested libraries preloaded.
set -Eeuo pipefail

# shellcheck source=../preload.sh
source /usr/local/share/postgis-with-extensions/preload.sh
pwe_load_registry

if [[ "${POWA_ROLE:-PRIMARY}" != PRIMARY ]]; then
	echo "postgis-with-extensions: error: POWA_ROLE=${POWA_ROLE} is not supported anymore;" \
		"set up standbys with pg_basebackup and password authentication instead." >&2
	exit 1
fi

if ! pwe_powa_requested; then
	exit 0
fi

psql=(psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --no-password --no-psqlrc)

loaded="$(PGHOST='' PGHOSTADDR='' "${psql[@]}" --dbname postgres --tuples-only --no-align \
	--command 'SHOW shared_preload_libraries')"
loaded=",${loaded//[[:space:]]/},"
# A shared_preload_libraries option, or an overridden entrypoint, can leave them out.
IFS=',' read -r -a required <<<"${pwe_requires[powa]:-}"
missing=()
for lib in "${required[@]}"; do
	if [[ "$loaded" != *",$lib,"* ]]; then
		missing+=("$lib")
	fi
done
if ((${#missing[@]})); then
	echo "postgis-with-extensions: skipping the PoWA setup, which needs ${missing[*]} preloaded" >&2
	exit 0
fi

PGHOST='' PGHOSTADDR='' "${psql[@]}" --dbname postgres --file /usr/local/src/install_all_powa_ext.sql
if [[ -n "${POWA_EXTRA_SQL:-}" ]]; then
	PGHOST='' PGHOSTADDR='' "${psql[@]}" --dbname powa --command "$POWA_EXTRA_SQL"
fi
