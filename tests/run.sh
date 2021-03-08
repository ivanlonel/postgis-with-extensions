#!/bin/sh

#./wait-for-it.sh sut:5432 --timeout=600 --strict -- echo "postgres is up"
while ! psql postgres -h postgres -p 5432 -U postgres -c 'SELECT 1'; do
    sleep 1
done

psql postgres -h postgres -p 5432 -U postgres -a -f /tests/create_extensions.sql