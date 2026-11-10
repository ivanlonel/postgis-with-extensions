-- https://github.com/pramsey/pgsql-gzip
CREATE EXTENSION gzip;

SELECT plan(3);
-- "hello", gzipped elsewhere (Python's gzip module).
SELECT is(
    convert_from(gunzip('\x1f8b08000000000002ffcb48cdc9c9070086a6103605000000'::bytea), 'UTF8'),
    'hello',
    'gzip data from elsewhere is read'
);
SELECT is(
    convert_from(gunzip(gzip(repeat('compressible ', 1000))), 'UTF8'),
    repeat('compressible ', 1000),
    'what it compresses comes back intact'
);
SELECT cmp_ok(length(gzip(repeat('compressible ', 1000))), '<', 200, 'and smaller');
SELECT * FROM finish(TRUE);
