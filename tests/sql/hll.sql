-- https://github.com/citusdata/postgresql-hll
CREATE EXTENSION hll;

-- Daily unique visitors, rolled up into a weekly estimate.
CREATE TABLE daily_uniques (day integer PRIMARY KEY, users hll);
INSERT INTO daily_uniques
SELECT
    day,
    hll_add_agg(hll_hash_integer(user_id))
FROM generate_series(1, 7) AS day, generate_series(day * 1000, day * 1000 + 1999) AS user_id
GROUP BY day;

SELECT plan(3);
SELECT is(
    (SELECT hll_cardinality(hll_add_agg(hll_hash_integer(n))) FROM generate_series(1, 10) AS n),
    10::float8,
    'small sets are counted exactly'
);
SELECT ok(
    (
        SELECT abs(hll_cardinality(users) - 2000) < 200 FROM daily_uniques
        WHERE day = 1
    ),
    'distinct values are estimated'
);
-- Days overlap by 1000 users: 1000 to 8999 are 8000 distinct users.
SELECT ok(
    (SELECT abs(hll_cardinality(hll_union_agg(users)) - 8000) < 800 FROM daily_uniques),
    'estimates combine'
);
SELECT * FROM finish(TRUE);
