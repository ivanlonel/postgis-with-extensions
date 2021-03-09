#!/bin/sh
# Adapted from https://docs.docker.com/compose/startup-order/

set -eu
  
uri="$2"
cmd="$@"
  
until PGPASSWORD=${POSTGRES_PASSWORD:-} psql "$uri" -c '\q'; do
    >&2 echo "Postgres is unavailable - sleeping"
    sleep 1
done
  
>&2 echo "Postgres is up - executing command"
exec $cmd