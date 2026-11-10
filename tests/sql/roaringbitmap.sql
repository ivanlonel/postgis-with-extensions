-- https://github.com/ChenHuajun/pg_roaringbitmap
CREATE EXTENSION roaringbitmap;

SELECT '{ 1 ,  -2  , 555555 ,  -4  ,2147483647,-2147483648}'::roaringbitmap;
SELECT set_config('roaringbitmap.output_format', 'array', FALSE);
SELECT '\x3a30000000000000'::roaringbitmap;
SELECT roaringbitmap('{1,-2,-3}') & roaringbitmap('{-3,-4,5}');
SELECT roaringbitmap('{1,2,3}') | roaringbitmap('{3,4,5}');
SELECT roaringbitmap('{1,2,3}') | 6;
SELECT 1 | roaringbitmap('{1,2,3}');
SELECT rb_xor(roaringbitmap('{}'), roaringbitmap('{3,4,5}'));
SELECT roaringbitmap('{1,2,3}') - roaringbitmap('{}');
SELECT roaringbitmap('{-1,-2,3}') - -1;
SELECT roaringbitmap('{-2,-1,0,1,2,3,2147483647,-2147483648}') << 4294967296;
SELECT roaringbitmap('{-2,-1,0,1,2,3,2147483647,-2147483648}') >> -2;
SELECT roaringbitmap('{1,2,3}') @> roaringbitmap('{3,2}');
SELECT roaringbitmap('{1,2,3}') @> 1;
SELECT roaringbitmap('{1,-3}') <@ roaringbitmap('{-3,1,1000}');
SELECT 6 <@ roaringbitmap('{}');
SELECT roaringbitmap('{1,2,3}') && roaringbitmap('{3,4,5}');
SELECT roaringbitmap('{1,2}') = roaringbitmap('{2,1}');
SELECT roaringbitmap('{1,2,3}') <> roaringbitmap('{3,1,2}');
SELECT rb_build('{1,-2,555555,-4,2147483647,-2147483648}'::int[]);
SELECT rb_to_array('{-1,2,555555,-4}'::roaringbitmap);
SELECT rb_is_empty('{}');
SELECT rb_max('{1,10,100,2147483647,-2147483648,-1}');
SELECT rb_min('{1,10,100,2147483647,-2147483648,-1}');
SELECT rb_iterate('{1,10,100,2147483647,-2147483648,-1}');

SELECT plan(1);
SELECT is(rb_cardinality('{1,10,100}'), 3::bigint, 'bitmaps count their members');
SELECT * FROM finish(TRUE);
