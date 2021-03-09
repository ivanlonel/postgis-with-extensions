#!/bin/sh
# Adapted from https://docs.docker.com/compose/startup-order/

set -eu
  
uri="$2"
cmd="$@"

>&2 echo "Sleeping 30 seconds to skip initial server restarts"
sleep 30

until psql "$uri" -c '\q'; do
    >&2 echo "Postgres is unavailable - sleeping"
    sleep 1
done
  
>&2 echo "Postgres is up - executing command"
exec $cmd