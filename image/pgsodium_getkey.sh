#!/usr/bin/env bash
# Print the root key that pgsodium and Supabase Vault load at startup when preloaded: 64 hex
# digits. The key is generated once, then kept in the data directory (the server's working
# directory) as pgsodium_root.key.
#
# This keeps the key next to the data it protects: point pgsodium.getkey_script and
# vault.getkey_script at a script fetching it from a key manager instead for real protection.
set -Eeuo pipefail

key=pgsodium_root.key
if [[ ! -s "$key" ]]; then
	umask 077
	od --address-radix=n --format=x1 --read-bytes=32 /dev/urandom | tr -d ' \n' >"$key.tmp"
	mv "$key.tmp" "$key"
fi
cat "$key"
