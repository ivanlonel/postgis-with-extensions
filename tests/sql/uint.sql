-- https://github.com/petere/pguint
CREATE EXTENSION uint;

CREATE TEMP TABLE uint_test (
    i1 int1,  -- signed 8-bit integer
    u1 uint1, -- unsigned 8-bit integer
    u2 uint2, -- unsigned 16-bit integer
    u4 uint4, -- unsigned 32-bit integer
    u8 uint8  -- unsigned 64-bit integer
);
INSERT INTO uint_test VALUES (-128, 0, 0, 0, 0), (127, 255, 65535, 4294967295, 18446744073709551615);

SELECT plan(5);
SELECT is((SELECT max(u8)::text FROM uint_test), '18446744073709551615', 'uint8 holds 2^64 - 1');
SELECT is((SELECT max(u4)::text FROM uint_test), '4294967295', 'uint4 holds 2^32 - 1');
SELECT is((SELECT min(i1)::text FROM uint_test), '-128', 'int1 holds -128');
SELECT throws_ok($$SELECT 255::uint1 + 1::uint1$$, NULL, NULL, 'overflows are caught');
SELECT throws_ok($$SELECT (-1)::uint4$$, NULL, NULL, 'negative values are rejected');
SELECT * FROM finish(TRUE);
