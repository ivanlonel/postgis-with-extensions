# shellcheck shell=bash
# Helpers for the scripts that stage third-party builds for PG_MAJOR (fetch-vendor.sh and
# fetch-vendor-extended.sh). Sourcing this file creates the /out staging directories and a work
# directory removed on exit.
# shellcheck disable=SC2034  # the scripts sourcing this file read extdir and /etc/os-release's variables

: "${PG_MAJOR:?}"

# shellcheck source=/dev/null
. /etc/os-release

libdir="/out$(pg_config --pkglibdir)"
extdir="/out$(pg_config --sharedir)/extension"
mkdir -p "$libdir" "$extdir"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

# Download URL $2 to file $1.
fetch() {
	if ! curl --fail --silent --show-error --location --retry 3 --output "$1" "$2"; then
		echo "failed to download $2" >&2
		return 1
	fi
}

# Copy the libraries and extension files found anywhere under directory $1 into /out. Some
# upstream packages install them under paths PostgreSQL doesn't read, or bundle stray files.
install_extension_files() {
	find "$1" -type f -name '*.so' -exec install -m 0755 -t "$libdir" {} +
	find "$1" -type f \( -name '*.control' -o -name '*.sql' \) -exec install -m 0644 -t "$extdir" {} +
}

# Unpack the .deb at URL $2 and copy its extension files (see install_extension_files).
extract_deb() {
	fetch "$workdir/$1.deb" "$2"
	dpkg-deb --extract "$workdir/$1.deb" "$workdir/$1"
	install_extension_files "$workdir/$1"
}

# Strip the staged libraries named $@: upstream builds often ship their debug information, which
# can be most of their size.
strip_libraries() {
	local name
	for name; do
		strip --strip-unneeded "$libdir/$name"
	done
}
