#!/usr/bin/env bash
# Entrypoint wrapper around the official docker-entrypoint.sh.
#
# On every start, adds the libraries requested through SHARED_PRELOAD_LIBRARIES to the server's
# shared_preload_libraries, together with the defaults those libraries need. It only ever adds:
# libraries the cluster's own configuration preloads are kept. Our options are placed before the
# user's, so any `-c` the user passes still wins. When SHARED_PRELOAD_LIBRARIES is unset and the
# cluster already exists, this script changes nothing.
set -Eeuo pipefail

readonly upstream_entrypoint=/usr/local/bin/docker-entrypoint.sh

log() {
	printf 'postgis-with-extensions: %s\n' "$*" >&2
}

die() {
	log "error: $*"
	exit 1
}

# Mirror docker-entrypoint.sh: a leading flag means "run the server with these options".
if [[ "${1:-}" == -* ]]; then
	set -- postgres "$@"
fi
if [[ "${1:-}" != postgres ]]; then
	exec "$upstream_entrypoint" "$@"
fi
for arg in "${@:2}"; do
	case "$arg" in
	-'?' | --help | --describe-config | -V | --version | -C)
		exec "$upstream_entrypoint" "$@"
		;;
	esac
done

# Reuse the official helpers: when sourced, docker-entrypoint.sh only defines its functions.
# They expect unset variables to expand to empty strings, hence the temporary `set +u`.
set +u
# shellcheck source=/dev/null
source "$upstream_entrypoint"
docker_setup_env
if [[ "$(id -u)" == 0 ]]; then
	# Fix permissions as root, exactly like upstream, then continue as the postgres user.
	docker_create_db_directories
	exec gosu postgres "${BASH_SOURCE[0]}" "$@"
fi
set -u

# shellcheck source=preload.sh
source /usr/local/share/postgis-with-extensions/preload.sh
pwe_load_registry

user_args=("${@:2}")
requested="${SHARED_PRELOAD_LIBRARIES:-}"
requested="${requested//[[:space:]]/}"
fresh=1
if [[ -s "$PGDATA/PG_VERSION" ]]; then
	fresh=0
fi

if [[ -z "${requested//,/}" ]] && { ((! fresh)) || [[ -z "${PWE_DEFAULT_PRELOAD:-}" ]]; }; then
	exec "$upstream_entrypoint" "$@"
fi

# Print the value of GUC $1 as the existing cluster's configuration (and the user's options)
# sets it. Fails for a new cluster, or when an extension GUC isn't set anywhere.
configured_setting() {
	if ((fresh)); then
		return 1
	fi
	postgres "${user_args[@]}" -C "$1" 2>/dev/null
}

# A shared_preload_libraries passed by the user as an option overrides the configuration files,
# so that's the list to extend, in place.
spl_index=-1
for i in "${!user_args[@]}"; do
	case "${user_args[$i]}" in
	-c)
		case "${user_args[$((i + 1))]:-}" in
		shared_preload_libraries=* | shared-preload-libraries=*) spl_index=$((i + 1)) ;;
		esac
		;;
	-cshared_preload_libraries=* | -cshared-preload-libraries=* | \
		--shared_preload_libraries=* | --shared-preload-libraries=*)
		spl_index=$i
		;;
	esac
done

if ((spl_index >= 0)); then
	configured="${user_args[$spl_index]#*=}"
elif ((fresh)); then
	configured="$(pwe_default_libraries | paste -sd, -)"
else
	configured="$(configured_setting shared_preload_libraries || true)"
fi

declare -A present=()
effective=()
while IFS= read -r lib; do
	if [[ -z "${present[$lib]:-}" ]]; then
		present[$lib]=1
		effective+=("$lib")
	fi
done < <(pwe_expand "$configured")

# Collect the requested libraries and their requirements.
declare -A selected=()
wanted=()
select_library() {
	local lib="$1" dependency
	local -a dependencies=()
	if [[ -n "${selected[$lib]:-}" ]]; then
		return 0
	fi
	if ! pwe_available "$lib"; then
		local -a known=()
		mapfile -t known < <(pwe_expand all)
		die "SHARED_PRELOAD_LIBRARIES: no shared library '$lib' in this image (PostgreSQL $PG_MAJOR)." \
			"Available presets: legacy, all. Libraries: ${known[*]}."
	fi
	selected[$lib]=1
	IFS=',' read -r -a dependencies <<<"${pwe_requires[$lib]:-}"
	for dependency in "${dependencies[@]}"; do
		if [[ -n "$dependency" ]]; then
			select_library "$dependency"
		fi
	done
	wanted+=("$lib")
}
mapfile -t requested_libraries < <(pwe_expand "$requested")
for lib in "${requested_libraries[@]}"; do
	select_library "$lib"
done

# Registry libraries go in canonical order, after which come any others, in request order.
added=()
mapfile -t added < <(
	for lib in "${wanted[@]}"; do
		if [[ -z "${present[$lib]:-}" && ! ("$lib" == powa && "${POWA_LOCAL_SNAPSHOT:-YES}" == NO) ]]; then
			printf '%s\t%s\n' "${pwe_rank[$lib]:-9999}" "$lib"
		fi
	done | sort -s -n -k1,1 | cut -f2
)
effective+=("${added[@]}")

# Libraries that must load before every other one (Citus refuses to start otherwise) go first,
# even when the cluster's own list already has them after others: that list couldn't start.
ordered=()
for lib in "${effective[@]}"; do
	if [[ -n "${pwe_first[$lib]:-}" ]]; then
		ordered+=("$lib")
	fi
done
for lib in "${effective[@]}"; do
	if [[ -z "${pwe_first[$lib]:-}" ]]; then
		ordered+=("$lib")
	fi
done
reordered=0
if [[ "${ordered[*]}" != "${effective[*]}" ]]; then
	reordered=1
fi
effective=("${ordered[@]}")

flags=()
if ((fresh || ${#added[@]} || reordered)); then
	value="$(
		IFS=,
		printf '%s' "${effective[*]}"
	)"
	if ((spl_index >= 0)); then
		user_args[spl_index]="${user_args[$spl_index]%%=*}=$value"
	else
		flags+=(-c "shared_preload_libraries=$value")
	fi
fi

if ((${#added[@]})); then
	log "adding to shared_preload_libraries: ${added[*]}"
	cron_db="${PG_CRON_DB:-$POSTGRES_DB}"
	partman_db="${PG_PARTMAN_DB:-$POSTGRES_DB}"
	for lib in "${added[@]}"; do
		IFS=';' read -r -a lib_settings <<<"${pwe_settings[$lib]:-}"
		for setting in "${lib_settings[@]}"; do
			if [[ -z "$setting" ]]; then
				continue
			fi
			name="${setting%%=*}"
			setting_value="${setting#*=}"
			setting_value="${setting_value//@CRON_DB@/$cron_db}"
			setting_value="${setting_value//@PARTMAN_DB@/$partman_db}"
			if [[ "$name" == *.* ]]; then
				# Extension GUC: a default, unless the configuration already sets it.
				if ! configured_setting "$name" >/dev/null; then
					flags+=(-c "$name=$setting_value")
				fi
			elif [[ "$(configured_setting "$name" || true)" != "$setting_value" ]]; then
				# Core GUC the library requires.
				flags+=(-c "$name=$setting_value")
			fi
		done
	done

	workers=8
	for lib in "${effective[@]}"; do
		workers=$((workers + ${pwe_workers[$lib]:-0}))
	done
	current_workers="$(configured_setting max_worker_processes || echo 8)"
	if ((workers > current_workers)); then
		flags+=(-c "max_worker_processes=$workers")
	fi
fi

exec "$upstream_entrypoint" postgres "${flags[@]}" "${user_args[@]}"
