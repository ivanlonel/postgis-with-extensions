-- https://github.com/ossc-db/pg_hint_plan
LOAD 'pg_hint_plan';

CREATE TEMP TABLE t1 AS SELECT
	3 * id AS id,
	random()
FROM generate_series(1, 200000) AS t (id);
ALTER TABLE t1 ADD PRIMARY KEY (id);

CREATE TEMP TABLE t2 AS SELECT
	id,
	random()
FROM generate_series(1, 600000) AS t (id);
ALTER TABLE t2 ADD PRIMARY KEY (id);

CREATE TEMP TABLE t3 AS SELECT
	2 * id AS id,
	random()
FROM generate_series(1, 300000) AS t (id);
ALTER TABLE t3 ADD PRIMARY KEY (id);

ANALYZE t1, t2, t3;

EXPLAIN (COSTS OFF, TIMING OFF)
SELECT *
FROM t1
INNER JOIN t2 USING (id)
INNER JOIN t3 USING (id);

EXPLAIN (COSTS OFF, TIMING OFF)
/*+ Leading((t3 (t2 t1))) NestLoop(t1 t2 t3) */
SELECT *
FROM t1
INNER JOIN t2 USING (id)
INNER JOIN t3 USING (id);
