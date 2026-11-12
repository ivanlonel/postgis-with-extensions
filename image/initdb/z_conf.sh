#!/usr/bin/env bash
# Append the image's defaults to postgresql.conf when a new cluster is initialized.
#
# With an image-level default preload list (PostGIS 3.6 images), this writes the same block as
# earlier releases of this image: the "legacy" preload list, merged with any list an earlier init
# script appended, and the settings those libraries rely on. From PostGIS 3.7 on, nothing is
# preloaded by default and only the settings that don't depend on a preloaded library remain;
# libraries requested through SHARED_PRELOAD_LIBRARIES are handled on every start by the
# entrypoint wrapper instead.
set -Eeuo pipefail

# shellcheck source=../preload.sh
source /usr/local/share/postgis-with-extensions/preload.sh
pwe_load_registry

conf="$PGDATA/postgresql.conf"
trusted_plugins='pgoutput, test_decoding, wal2json, pglogical_output, pg_squeeze, pg_rewrite, decoderbufs, decoder_raw, pgactive'
extdir="/usr/share/postgresql/$PG_MAJOR/extension"

# The JVM-based extensions of the extended images don't work without these.
append_jvm_defaults() {
	if [[ -e "$extdir/pljava.control" ]]; then
		cat >>"$conf" <<-EOT

			# PL/Java: from Java 18 on, the JVM only starts once the security manager mode is chosen
			pljava.vmoptions = '-Djava.security.manager=allow'
		EOT
	fi
	if [[ -e "$extdir/hdfs_fdw.control" ]]; then
		cat >>"$conf" <<-EOT

			# hdfs_fdw: the JVM to load (hdfs_fdw.classpath also needs the Hive JDBC driver's jars)
			hdfs_fdw.jvmpath = '/usr/lib/jvm/default-java/lib/server'
		EOT
	fi
}

if [[ -z "${PWE_DEFAULT_PRELOAD:-}" ]]; then
	cat >>"$conf" <<-EOT

		# postgis-with-extensions defaults

		# Logical decoding output plugins shipped in this image (PostgreSQL only trusts pgoutput and test_decoding by default)
		output_plugin_libraries = '$trusted_plugins'

		# MobilityDB recommendation
		max_locks_per_transaction = 128

		# Logical replication and decoding (pglogical, wal2json)
		wal_level = 'logical'
		max_replication_slots = 10
		max_wal_senders = 10
	EOT
	append_jvm_defaults
	exit 0
fi

# The last shared_preload_libraries line wins in postgresql.conf, so merge into it.
previous="$(sed -nE "s/^[[:space:]]*shared_preload_libraries[[:space:]]*=[[:space:]]*'([^']*)'.*/\1/p" "$conf" | tail -n 1)"
mapfile -t libraries < <(
	{
		pwe_expand "$previous"
		pwe_default_libraries
	} | awk 'NF && !seen[$0]++'
)
preload="$(
	IFS=,
	printf '%s' "${libraries[*]}"
)"
# Earlier releases set 10, which left some of these libraries' background workers without a slot.
workers=8
for lib in "${libraries[@]}"; do
	workers=$((workers + ${pwe_workers[$lib]:-0}))
done

cat >>"$conf" <<-EOT
	listen_addresses = '*'

	shared_preload_libraries = '$preload'

	# pg_cron
	cron.database_name = '${PG_CRON_DB:-${POSTGRES_DB:-${POSTGRES_USER:-postgres}}}'

	# pg_partman
	pg_partman_bgw.dbname = '${PG_PARTMAN_DB:-${POSTGRES_DB:-${POSTGRES_USER:-postgres}}}'

	# pg_show_plans: explaining each query before it runs crashes inserts into TimescaleDB hypertables
	# (https://github.com/timescale/timescaledb/pull/10417). Set to on to use it anyway.
	pg_show_plans.is_enabled = off

	# Logical decoding output plugins shipped in this image (PostgreSQL only trusts pgoutput and test_decoding by default)
	output_plugin_libraries = '$trusted_plugins'

	# MobilityDB recommendation
	max_locks_per_transaction = 128
	timescaledb.telemetry_level = off

	# PoWA
	powa.frequency = 30s

	# pglogical
	wal_level = 'logical'
	max_replication_slots = 10  # one per node needed on provider node
	max_wal_senders = 10        # one per node needed on provider node
	track_commit_timestamp = on # needed for last/first update wins conflict resolution

	# PostgreSQL's 8 background workers, plus those of the preloaded libraries
	max_worker_processes = $workers
EOT
append_jvm_defaults
