#!/bin/bash
set -Eeuo pipefail

# Currently, the original entrypoint script only reads credentials from environment.
# This alternative entrypoint allows reading them from files

file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"

	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

file_env "PGADMIN_DEFAULT_EMAIL"
file_env "PGADMIN_DEFAULT_PASSWORD"

source /entrypoint.sh
