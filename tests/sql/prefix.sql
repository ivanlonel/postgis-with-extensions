-- https://github.com/dimitri/prefix
CREATE EXTENSION prefix;

-- Telephone prefixes, matched against numbers (the extension's purpose).
CREATE TABLE prefixes (prefix prefix_range PRIMARY KEY, operator text);
INSERT INTO prefixes
SELECT
    format('56%s', i)::prefix_range,
    'operator ' || i
FROM generate_series(10, 9999) AS i;
INSERT INTO prefixes VALUES ('55', 'Brazil'), ('5511', 'Sao Paulo'), ('551199', 'Sao Paulo mobile');
CREATE INDEX prefixes_prefix_idx ON prefixes USING gist (prefix gist_prefix_range_ops);
ANALYZE prefixes;

SELECT plan(4);
SELECT ok('123'::prefix_range @> '123456', 'prefix ranges contain longer prefixes');
SELECT is(
    (
        SELECT operator FROM prefixes
        WHERE prefix @> '5511998765432'
        ORDER BY length(prefix::text) DESC
        LIMIT 1
    ),
    'Sao Paulo mobile',
    'the longest matching prefix is found'
);
SELECT is(
    (
        SELECT count(*) FROM prefixes
        WHERE prefix @> '5511998765432'
    ),
    3::bigint,
    'every matching prefix is found'
);
SELECT matches(
    plan_of($$SELECT * FROM prefixes WHERE prefix @> '5511998765432'$$),
    'prefixes_prefix_idx',
    'prefix searches use the GiST index'
);
SELECT * FROM finish(TRUE);
