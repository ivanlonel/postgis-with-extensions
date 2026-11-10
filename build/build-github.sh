#!/usr/bin/env bash
# Build the GitHub-hosted extensions of a package list for PG_MAJOR, with PGXS, into /out.
#
# Usage: build-github <package list>
# Each line: <owner/repo> <ref> [option...], where <ref> is a tag, or a commit followed by
# branch=<branch> (the branch Renovate follows for that commit). Options:
#   subdir=<dir>     build this directory of the repository instead of its root
#   pg>=N, pg<=N     only build for these PostgreSQL majors
#   NAME=value       make variable passed to the build
set -Eeuo pipefail

: "${PG_MAJOR:?}"

if (($# != 1)); then
	echo "usage: ${0##*/} <package list>" >&2
	exit 64
fi

mkdir -p /out
while read -r repo ref rest; do
	case "$repo" in '' | '#'*) continue ;; esac
	read -r -a options <<<"$rest"
	build=(build-pgxs)
	make_args=()
	wanted=1
	for option in "${options[@]}"; do
		case "$option" in
		branch=*) ;;
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
	if [[ "$ref" =~ ^[0-9a-f]{40}$ ]]; then
		url="https://github.com/$repo/archive/$ref.tar.gz"
	else
		url="https://github.com/$repo/archive/refs/tags/$ref.tar.gz"
	fi
	echo "building $repo $ref"
	"${build[@]}" "$url" "${make_args[@]}"
done <"$1"
