#!/usr/bin/env bash
# Download a pgrx extension's source archive and package it for PG_MAJOR, copying its files into the
# /out staging tree with the library stripped.
#
# Usage: build-pgrx [--subdir=<dir>] <archive URL (.tar.*)>
# --subdir packages a crate of the sources (in a larger repository) instead of their root. The
# crate pins its pgrx version (pgrx = "=X.Y.Z"), and cargo-pgrx must be that exact version: each
# build installs its own.
set -Eeuo pipefail

: "${PG_MAJOR:?}" "${CARGO_HOME:?}"

subdir=
if [[ "${1:-}" == --subdir=* ]]; then
	subdir="${1#--subdir=}"
	shift
fi

if (($# != 1)); then
	echo "usage: ${0##*/} [--subdir=<dir>] <archive URL>" >&2
	exit 64
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

curl --fail --silent --show-error --location --retry 3 --output "$workdir/archive" "$1"
mkdir "$workdir/src"
tar -xf "$workdir/archive" -C "$workdir/src" --strip-components=1
srcdir="$workdir/src${subdir:+/$subdir}"

# The first pgrx dependency line, as `pgrx = "=X.Y.Z"` or `pgrx = { version = "=X.Y.Z", ... }`.
pgrx_version="$(sed -nE '/^pgrx[[:space:]]*=/{s/^[^"]*"=?([^"]+)".*/\1/p;q}' "$srcdir/Cargo.toml")"
if [[ -z "$pgrx_version" ]]; then
	echo "no pgrx dependency in $srcdir/Cargo.toml" >&2
	exit 1
fi

pg_config="$(command -v pg_config)"
cargo install --locked cargo-pgrx --version "$pgrx_version"
cargo pgrx init "--pg${PG_MAJOR}=$pg_config"
(
	cd "$srcdir"
	cargo pgrx package --pg-config "$pg_config" --no-default-features --features "pg${PG_MAJOR}" \
		--out-dir "$workdir/package"
)

find "$workdir/package" -type f -name '*.so' -exec strip --strip-unneeded {} +
mkdir -p /out
cp -a "$workdir/package/." /out/

# Only /out leaves this stage: keep the cached layer small.
rm -rf "$CARGO_HOME/registry" "$CARGO_HOME/git"
