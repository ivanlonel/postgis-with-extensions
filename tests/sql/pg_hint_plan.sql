-- https://github.com/ossc-db/pg_hint_plan
LOAD 'pg_hint_plan';

CREATE TABLE t1 AS SELECT
    3 * id AS id,
    random() AS r
FROM generate_series(1, 200000) AS t (id);
ALTER TABLE t1 ADD PRIMARY KEY (id);

CREATE TABLE t2 AS SELECT
    id,
    random() AS r
FROM generate_series(1, 600000) AS t (id);
ALTER TABLE t2 ADD PRIMARY KEY (id);

ANALYZE t1, t2;

-- Hints are read from a comment at the head of the statement, so put them before EXPLAIN.
CREATE FUNCTION hinted_plan(hint text, query text) RETURNS text LANGUAGE plpgsql AS $$
DECLARE
    line text;
    plan text := '';
BEGIN
    FOR line IN EXECUTE format('/*+ %s */ EXPLAIN (COSTS OFF) %s', hint, query) LOOP
        plan := plan || line || E'\n';
    END LOOP;
    RETURN plan;
END
$$;

SELECT plan(4);
SELECT matches(plan_of('SELECT * FROM t1 WHERE id = 3'), 'Index Scan', 'without hints, the index is used');
SELECT matches(
    hinted_plan('SeqScan(t1)', 'SELECT * FROM t1 WHERE id = 3'), 'Seq Scan on t1', 'scan hints are obeyed'
);
SELECT matches(
    hinted_plan('NestLoop(t1 t2)', 'SELECT * FROM t1 INNER JOIN t2 USING (id)'),
    'Nested Loop',
    'join method hints are obeyed'
);
SELECT matches(
    hinted_plan('Leading((t2 t1)) HashJoin(t1 t2)', 'SELECT * FROM t1 INNER JOIN t2 USING (id)'),
    'Hash Join.*Seq Scan on t2.*Seq Scan on t1',
    'join order hints are obeyed'
);
SELECT * FROM finish(TRUE);
