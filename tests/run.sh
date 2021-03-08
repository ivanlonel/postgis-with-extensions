#!/bin/sh

PG_URI="postgresql://postgres:postgres@postgres:5433/postgres"

#./wait-for-it.sh sut:5432 --timeout=600 --strict -- echo "postgres is up"
while ! psql $PG_URI -c 'SELECT 1'; do
    sleep 1
done

psql $PG_URI -a -f /tests/create_extensions.sql