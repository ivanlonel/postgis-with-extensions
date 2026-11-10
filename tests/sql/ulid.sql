-- https://github.com/pksunkara/pgx_ulid
CREATE EXTENSION ulid;

SELECT plan(3);
SELECT is(
    '01ARZ3NDEKTSV4RRFFQ69G5FAV'::ulid::timestamptz,
    '2016-07-30 23:54:10.259+00'::timestamptz,
    'ULIDs carry their creation time'
);
SELECT is(
    '01ARZ3NDEKTSV4RRFFQ69G5FAV'::ulid::uuid::ulid::text,
    '01ARZ3NDEKTSV4RRFFQ69G5FAV',
    'they convert to UUIDs and back'
);
SELECT is((SELECT count(DISTINCT gen_ulid()) FROM generate_series(1, 1000)), 1000::bigint, 'generated ones are unique');
SELECT * FROM finish(TRUE);
