#!/usr/bin/env bash
# Install the runtime extension packages into the final image.
#
# Usage: install-runtime.sh <apt package list> [local .deb files...]
#
# - Holds the base image's PostGIS packages so a tag never silently changes its PostGIS version.
# - Installs the PGDG/Debian packages whose constraints match this PG major and PostGIS series,
#   together with the given third-party .deb files.
# - On PostGIS >= 3.7, which no longer bundles postgis_tiger_geocoder and address_standardizer,
#   backfills the tiger geocoder on PG releases PGDG doesn't package it for, and recreates the
#   names that 3.6-era clusters reference (address_standardizer-3.so and the "-3" aliases).
set -Eeuo pipefail

: "${PG_MAJOR:?}" "${POSTGIS_MAJOR:?}" "${POSTGIS_VERSION:?}"

if (($# < 1)); then
	echo "usage: ${0##*/} <apt package list> [local .deb files...]" >&2
	exit 64
fi
package_list="$1"
shift

# POSTGIS_VERSION is the base image's full package version, e.g. "3.7.0+dfsg-1.pgdg13+1".
postgis_series="$(sed -E 's/^([0-9]+)\.([0-9]+).*/\1.\2/' <<<"$POSTGIS_VERSION")"
libdir="/usr/lib/postgresql/${PG_MAJOR}/lib"
extdir="/usr/share/postgresql/${PG_MAJOR}/extension"

# Print the packages of the list whose constraints all hold.
select_packages() {
	local package constraints constraint include
	while read -r package constraints; do
		[[ -z "$package" || "$package" == \#* ]] && continue
		include=1
		for constraint in $constraints; do
			case "$constraint" in
			pg\>=*) ((PG_MAJOR >= ${constraint#pg>=})) || include=0 ;;
			pg\<=*) ((PG_MAJOR <= ${constraint#pg<=})) || include=0 ;;
			postgis\>=*) dpkg --compare-versions "$postgis_series" ge "${constraint#postgis>=}" || include=0 ;;
			postgis\<=*) dpkg --compare-versions "$postgis_series" le "${constraint#postgis<=}" || include=0 ;;
			*)
				echo "unknown constraint '$constraint' for $package" >&2
				return 1
				;;
			esac
		done
		if ((include)); then
			printf '%s\n' "${package//%/$PG_MAJOR}"
		fi
	done <"$package_list"
}

mapfile -t packages < <(select_packages)

apt-mark hold "postgresql-${PG_MAJOR}-postgis-${POSTGIS_MAJOR}" "postgresql-${PG_MAJOR}-postgis-${POSTGIS_MAJOR}-scripts"
apt-get update
apt-get install -y --no-install-recommends "${packages[@]}" "$@"

if dpkg --compare-versions "$postgis_series" ge 3.7; then
	# PGDG packages the standalone tiger geocoder for PG 16+ only. It is pure SQL (arch: all), so
	# the PG 16 build's extension files serve older majors too, once stripped of what those majors
	# predate (the @extschema:<extension>@ references and no_relocate), as PostGIS's own build does.
	if [[ ! -e "$extdir/postgis_tiger_geocoder.control" ]]; then
		workdir="$(mktemp -d)"
		(cd "$workdir" && apt-get download postgresql-16-postgis-tiger-geocoder)
		dpkg-deb -x "$workdir"/postgresql-16-postgis-tiger-geocoder_*.deb "$workdir/root"
		cp -a "$workdir/root/usr/share/postgresql/16/extension/." "$extdir/"
		rm -rf "$workdir"
		if ((PG_MAJOR < 16)); then
			sed -i -E 's/@extschema:[^@]+@\.//g' "$extdir"/postgis_tiger_geocoder*.sql
			sed -i '/^no_relocate/d' "$extdir/postgis_tiger_geocoder.control"
		fi
	fi

	# Functions created by PostGIS 3.6's address_standardizer reference $libdir/address_standardizer-3.
	if [[ -e "$libdir/address_standardizer.so" && ! -e "$libdir/address_standardizer-3.so" ]]; then
		ln -s address_standardizer.so "$libdir/address_standardizer-3.so"
	fi

	# PostGIS 3.6 also offered these extensions under "-3" alias names.
	for extension in address_standardizer address_standardizer_data_us postgis_tiger_geocoder; do
		if [[ ! -e "$extdir/$extension.control" || -e "$extdir/$extension-3.control" ]]; then
			continue
		fi
		ln -s "$extension.control" "$extdir/$extension-3.control"
		for script in "$extdir/$extension--"*.sql; do
			ln -s "${script##*/}" "$extdir/$extension-3--${script##*/"$extension"--}"
		done
	done
fi

apt-get clean
# oracle-libs, oracle_fdw's Oracle Instant Client downloader, keeps the zips it fetched (~73 MiB)
# as a cache for re-runs; the unpacked client in /usr/lib/oracle is all the image needs.
rm -rf /var/lib/apt/lists/* /var/tmp/oracle-libs
