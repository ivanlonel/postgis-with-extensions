-- preload: pg_ivm
-- https://github.com/sraoss/pg_ivm
CREATE EXTENSION pg_ivm;

CREATE TABLE regions (id integer PRIMARY KEY, name text);
CREATE TABLE sales (id integer PRIMARY KEY, region_id integer REFERENCES regions, amount numeric);
INSERT INTO regions VALUES (1, 'north'), (2, 'south');
INSERT INTO sales VALUES (1, 1, 10), (2, 2, 20);

SELECT pgivm.create_immv(
    'sales_by_region',
    $$
        SELECT r.name, sum(s.amount) AS total, count(*) AS n
        FROM sales AS s INNER JOIN regions AS r ON s.region_id = r.id
        GROUP BY r.name
    $$
);

-- Every change to the base tables updates the view in the same statement.
INSERT INTO sales VALUES (3, 1, 5);
UPDATE sales SET amount = 25
WHERE id = 2;
DELETE FROM sales
WHERE id = 1;

SELECT plan(1);
SELECT results_eq(
    'SELECT name, total, n FROM sales_by_region ORDER BY name',
    $$VALUES ('north', 5::numeric, 1::bigint), ('south', 25::numeric, 1::bigint)$$,
    'joins and aggregates are maintained incrementally'
);
SELECT * FROM finish(TRUE);
