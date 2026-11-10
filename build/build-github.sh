#!/usr/bin/env bash
# Build the GitHub-hosted extensions of a package list for PG_MAJOR, with PGXS, into /out.
#
# Usage: build-github <package list>
# Each line: <owner/repo> <ref> [option...], where <ref> is a tag, or a commit followed by
# branch=<branch> (the branch Renovate follows for that commit). Options:
#   subdir=<dir>     build this directory of the repository instead of its root
#   submodules       clone the repository with its submodules, which GitHub's archives leave out
#   pg>=N, pg<=N     only build for these PostgreSQL majors
#   NAME=value       make variable passed to the build
set -Eeuo pipefail

: "${PG_MAJOR:?}"

if (($# != 1)); then
	echo "usage: ${0##*/} <package list>" >&2
	exit 64
fi

clonedir="$(mktemp -d)"
trap 'rm -rf "$clonedir"' EXIT

# Fetch commit or tag $2 of GitHub repository $1, with its submodules, into a new directory under
# $clonedir, and print that directory.
clone() {
	local dir
	dir="$(mktemp -d -p "$clonedir")"
	git -C "$dir" init --quiet
	git -C "$dir" fetch --quiet --depth 1 "https://github.com/$1" "$2"
	git -C "$dir" -c advice.detachedHead=false checkout --quiet FETCH_HEAD
	git -C "$dir" submodule --quiet update --init --recursive --depth 1
	echo "$dir"
}

mkdir -p /out
while read -r repo ref rest; do
	case "$repo" in '' | '#'*) continue ;; esac
	read -r -a options <<<"$rest"
	build=(build-pgxs)
	make_args=()
	wanted=1
	submodules=0
	for option in "${options[@]}"; do
		case "$option" in
		branch=*) ;;
		submodules) submodules=1 ;;
		subdir=*) build+=("--$option") ;;
		pg\>=*) ((PG_MAJOR >= ${option#pg>=})) || wanted=0 ;;
		pg\<=*) ((PG_MAJOR <= ${option#pg<=})) || wanted=0 ;;
		*) make_args+=("$option") ;;
		esac
	done
	if ((! wanted)); then
		echo "skipping $repo on PostgreSQL $PG_MAJOR"
		continue
	fi
	echo "building $repo $ref"
	if ((submodules)); then
		source="$(clone "$repo" "$ref")"
	elif [[ "$ref" =~ ^[0-9a-f]{40}$ ]]; then
		source="https://github.com/$repo/archive/$ref.tar.gz"
	else
		source="https://github.com/$repo/archive/refs/tags/$ref.tar.gz"
	fi
	"${build[@]}" "$source" "${make_args[@]}"
done <"$1"
