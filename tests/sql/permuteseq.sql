-- https://github.com/dverite/permuteseq
CREATE EXTENSION permuteseq;

CREATE SEQUENCE s MINVALUE -10000 MAXVALUE 15000;

SELECT permute_nextval('s'::regclass, 123456789012345) FROM generate_series(-10000, -9990);
SELECT reverse_permute('s'::regclass, -545, 123456789012345);

SELECT plan(1);
SELECT is(
	range_decrypt_element(
		range_encrypt_element(91919191919, 1e10::bigint, 1e11::bigint, 123456789012345),
		1e10::bigint, 1e11::bigint, 123456789012345
	),
	91919191919::bigint,
	'encryption round-trips'
);
SELECT * FROM finish(TRUE);
