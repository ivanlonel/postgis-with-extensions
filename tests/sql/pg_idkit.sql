-- pg: >=15
-- https://github.com/VADOSWARE/pg_idkit
CREATE EXTENSION pg_idkit;

SELECT plan(3);
-- The ULID's timestamp is 23:54:10.259; pg_idkit extracts it to the second.
SELECT is(
    idkit_ulid_extract_timestamptz('01ARZ3NDEKTSV4RRFFQ69G5FAV'),
    '2016-07-30 23:54:10+00'::timestamptz,
    'ULID timestamps are extracted'
);
SELECT is(length(idkit_ksuid_generate_text()), 27, 'KSUIDs have 27 characters');
SELECT ok(
    idkit_uuidv7_extract_timestamptz(idkit_uuidv7_generate_text())
    BETWEEN now() - interval '1 minute' AND now() + interval '1 minute',
    'UUIDv7s carry the current time'
);
SELECT * FROM finish(TRUE);
