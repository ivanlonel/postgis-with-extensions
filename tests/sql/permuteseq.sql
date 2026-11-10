-- https://github.com/dverite/permuteseq
CREATE EXTENSION permuteseq;

CREATE SEQUENCE s MINVALUE 1 MAXVALUE 1000;
CREATE TABLE issued AS
SELECT permute_nextval('s'::regclass, 123456789012345) AS v FROM generate_series(1, 1000);

SELECT plan(4);
SELECT is(
    range_decrypt_element(
        range_encrypt_element(91919191919, 1e10::bigint, 1e11::bigint, 123456789012345),
        1e10::bigint, 1e11::bigint, 123456789012345
    ),
    91919191919::bigint,
    'encryption round-trips'
);
SELECT is(
    (
        SELECT count(DISTINCT v) FROM issued
        WHERE v BETWEEN 1 AND 1000
    ),
    1000::bigint,
    'sequence values are permuted within the sequence range'
);
SELECT isnt(
    (SELECT array_agg(v) FROM (SELECT v FROM issued LIMIT 10) AS first_ten),
    ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]::bigint[],
    'permuted values are not in sequence order'
);
SELECT is(
    (SELECT reverse_permute('s'::regclass, v, 123456789012345) FROM issued LIMIT 1),
    1::bigint,
    'permutations are reversed'
);
SELECT * FROM finish(TRUE);
