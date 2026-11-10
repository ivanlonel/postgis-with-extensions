-- https://github.com/hatarist/pg_xxhash
CREATE EXTENSION xxhash;

SELECT plan(6);
SELECT is(xxh32('test'), '3e2023cf', 'XXH32 matches the reference');
SELECT is(xxh64('test'), '4fdcca5ddb678139', 'XXH64 matches the reference');
SELECT is(length(xxh128('test')), 32, 'XXH128 hashes are 128-bit');
SELECT is(length(xxh3_64b('test')), 8, 'binary XXH3 hashes are 64-bit');
SELECT is(xxh3_64('test'), xxh3_64('test'), 'hashes are deterministic');
SELECT isnt(xxh3_64('test'), xxh3_64('tests'), 'hashes tell inputs apart');
SELECT * FROM finish(TRUE);
