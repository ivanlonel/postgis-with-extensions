#!/usr/bin/env bash
# Download a source archive and build it with PGXS, installing into the /out staging tree.
#
# Usage: build-pgxs [--subdir=<dir>] <archive URL (.tar.* or .zip)> [make variable assignments...]
# --subdir builds a directory of the archive instead of its root.
set -Eeuo pipefail

subdir=
if [[ "${1:-}" == --subdir=* ]]; then
	subdir="${1#--subdir=}"
	shift
fi

if (($# < 1)); then
	echo "usage: ${0##*/} [--subdir=<dir>] <archive URL> [make variables...]" >&2
	exit 64
fi

url="$1"
shift

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

curl --fail --silent --show-error --location --retry 3 --output "$workdir/archive" "$url"

mkdir "$workdir/src"
case "$url" in
*.zip) unzip -q "$workdir/archive" -d "$workdir/src" ;;
*) tar -xf "$workdir/archive" -C "$workdir/src" ;;
esac

# Archives normally hold a single top-level directory; fall back to the extraction root.
srcdir="$workdir/src"
mapfile -t entries < <(find "$srcdir" -mindepth 1 -maxdepth 1)
if ((${#entries[@]} == 1)) && [[ -d "${entries[0]}" ]]; then
	srcdir="${entries[0]}"
fi
if [[ -n "$subdir" ]]; then
	srcdir="$srcdir/$subdir"
fi

make -C "$srcdir" -j "$(nproc)" PG_CONFIG=pg_config "$@"
make -C "$srcdir" install DESTDIR=/out PG_CONFIG=pg_config "$@"
