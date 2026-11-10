-- https://github.com/ChenHuajun/pg_roaringbitmap
CREATE EXTENSION roaringbitmap;

SELECT set_config('roaringbitmap.output_format', 'array', FALSE);

SELECT plan(7);
SELECT is(rb_cardinality('{1,10,100}'), 3::bigint, 'bitmaps count their members');
SELECT is(
    rb_to_array(roaringbitmap('{1,2,3}') & roaringbitmap('{3,4,5}')), ARRAY[3], 'intersections'
);
SELECT is(
    rb_to_array(roaringbitmap('{1,2,3}') | roaringbitmap('{3,4,5}')), ARRAY[1, 2, 3, 4, 5], 'unions'
);
SELECT is(
    rb_to_array(rb_xor(roaringbitmap('{1,2,3}'), roaringbitmap('{3,4,5}'))),
    ARRAY[1, 2, 4, 5],
    'symmetric differences'
);
SELECT ok(roaringbitmap('{1,2,3}') @> roaringbitmap('{3,2}'), 'containment');
SELECT is(
    (SELECT rb_cardinality(rb_build_agg(i)) FROM generate_series(1, 100000) AS i),
    100000::bigint,
    'bitmaps aggregate'
);
SELECT is(
    (SELECT rb_cardinality(rb_or_agg(rb_build(ARRAY[i, i + 1]))) FROM generate_series(1, 10) AS i),
    11::bigint,
    'bitmaps union-aggregate'
);
SELECT * FROM finish(TRUE);
