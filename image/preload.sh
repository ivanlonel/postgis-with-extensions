# shellcheck shell=bash
# Helpers around the preload registry, sourced by the entrypoint wrapper and the init scripts.
# shellcheck disable=SC2034  # the scripts sourcing this file read the pwe_* arrays it fills

readonly PWE_REGISTRY=/usr/local/share/postgis-with-extensions/preload-libraries.txt
readonly PWE_LIBDIR="/usr/lib/postgresql/${PG_MAJOR}/lib"

declare -ga pwe_order=()
declare -gA pwe_rank=() pwe_preset=() pwe_requires=() pwe_workers=() pwe_settings=() pwe_first=()

# Load the registry into the pwe_* arrays.
pwe_load_registry() {
	local lib preset requires workers settings position
	while IFS='|' read -r lib preset requires workers settings position; do
		if [[ -z "$lib" || "$lib" == \#* ]]; then
			continue
		fi
		pwe_rank[$lib]="${#pwe_order[@]}"
		pwe_order+=("$lib")
		pwe_preset[$lib]="$preset"
		pwe_requires[$lib]="$requires"
		pwe_workers[$lib]="${workers:-0}"
		pwe_settings[$lib]="$settings"
		if [[ "$position" == first ]]; then
			pwe_first[$lib]=1
		fi
	done <"$PWE_REGISTRY"
}

# Succeed when the shared library $1 is installed.
pwe_available() {
	[[ -e "$PWE_LIBDIR/$1.so" ]]
}

# Print the libraries of the comma-separated list $1, one per line, expanding the presets
# "legacy" (the libraries preloaded by default before PostGIS 3.7) and "all" (every installed
# registry library not marked "none"). Whitespace and double quotes are ignored.
pwe_expand() {
	local list="${1//[[:space:]\"]/}" item lib
	local -a items=()
	IFS=',' read -r -a items <<<"$list"
	for item in "${items[@]}"; do
		case "$item" in
		'') ;;
		legacy | all)
			for lib in "${pwe_order[@]}"; do
				case "$item:${pwe_preset[$lib]}" in
				legacy:legacy | all:legacy | all:all)
					if pwe_available "$lib"; then
						printf '%s\n' "$lib"
					fi
					;;
				esac
			done
			;;
		*) printf '%s\n' "$item" ;;
		esac
	done
}

# Print the libraries the image itself preloads on new clusters (PWE_DEFAULT_PRELOAD), honouring
# POWA_LOCAL_SNAPSHOT=NO, which keeps PoWA's statistics extensions but not its own worker.
pwe_default_libraries() {
	local lib
	while IFS= read -r lib; do
		if [[ "$lib" != powa || "${POWA_LOCAL_SNAPSHOT:-YES}" != NO ]]; then
			printf '%s\n' "$lib"
		fi
	done < <(pwe_expand "${PWE_DEFAULT_PRELOAD:-}")
}

# Succeed when PoWA was requested, either by the image default or by SHARED_PRELOAD_LIBRARIES.
pwe_powa_requested() {
	local libraries
	# Captured first: with pipefail, `grep -q` exiting early could fail the pipeline via SIGPIPE.
	libraries="$(pwe_expand "${PWE_DEFAULT_PRELOAD:-},${SHARED_PRELOAD_LIBRARIES:-}")"
	grep -qx powa <<<"$libraries"
}
