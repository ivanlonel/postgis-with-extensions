-- https://github.com/apache/datasketches-postgresql
CREATE EXTENSION datasketches;

SELECT plan(2);
SELECT cmp_ok(
    (SELECT abs(hll_sketch_get_estimate(hll_sketch_build(i)) - 10000) FROM generate_series(1, 10000) AS i),
    '<',
    500::double precision,
    'HLL sketches estimate distinct counts'
);
SELECT cmp_ok(
    (
        SELECT abs(kll_float_sketch_get_quantile(kll_float_sketch_build(i::real), 0.5) - 5000)
        FROM generate_series(1, 10000) AS i
    ),
    '<',
    400::real,
    'KLL sketches estimate quantiles'
);
SELECT * FROM finish(TRUE);
