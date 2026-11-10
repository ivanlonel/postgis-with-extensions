-- https://github.com/dimitri/prefix
CREATE EXTENSION prefix;

SELECT plan(1);
SELECT ok('123'::prefix_range @> '123456', 'prefix ranges contain longer prefixes');
SELECT * FROM finish(TRUE);
