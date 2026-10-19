#!/bin/bash
set -Eeuo pipefail

# The inner sed finds the line number of the last match for the the regex ^\s*shared_preload_libraries\s*=
# The outer sed, operating on that line alone, extracts the text between single quotes after the equals sign
PREVIOUS_PRELOAD_LIBRARIES=$(sed -nE "$(sed -n '/^\s*shared_preload_libraries\s*=/ =' ${PGDATA}/postgresql.conf | tail -n 1) s/^\s*shared_preload_libraries\s*=\s*'(.*?)'/\1/p" ${PGDATA}/postgresql.conf)

NEW_PRELOAD_LIBRARIES="credcheck,pg_cron,pg_partman_bgw,pg_show_plans,pg_similarity,pg_squeeze,pg_stat_statements,pg_stat_kcache,pg_wait_sampling,pgaudit,pgauditlogtofile,pglogical,pgmemcache,plprofiler,plugin_debugger,postgis-3,set_user,timescaledb"

if [ "$PG_MAJOR" -le 17 ]; then
    NEW_PRELOAD_LIBRARIES="$NEW_PRELOAD_LIBRARIES,pglogical_ticker"
fi

cat >> ${PGDATA}/postgresql.conf << EOT
listen_addresses = '*'

shared_preload_libraries = '$(echo "$PREVIOUS_PRELOAD_LIBRARIES,$NEW_PRELOAD_LIBRARIES" | sed 's/^,//')'

# pg_cron
cron.database_name = '${PG_CRON_DB:-${POSTGRES_DB:-${POSTGRES_USER:-postgres}}}'

# pg_partman
pg_partman_bgw.dbname = '${PG_PARTMAN_DB:-${POSTGRES_DB:-${POSTGRES_USER:-postgres}}}'

# pg_show_plans: explaining each query before it runs crashes INSERTs into TimescaleDB hypertables
# (https://github.com/timescale/timescaledb/pull/10417). Set to on to use it anyway.
pg_show_plans.is_enabled = off

# Logical decoding output plugins shipped in this image (PostgreSQL only trusts pgoutput and test_decoding by default)
output_plugin_libraries = 'pgoutput, test_decoding, wal2json, pglogical_output, pg_squeeze'

# MobilityDB recomendation
max_locks_per_transaction = 128
timescaledb.telemetry_level = off

# pglogical
wal_level = 'logical'
max_worker_processes = 10   # one per database needed on provider node
                            # one per node needed on subscriber node
max_replication_slots = 10  # one per node needed on provider node
max_wal_senders = 10        # one per node needed on provider node
track_commit_timestamp = on # needed for last/first update wins conflict resolution
EOT
