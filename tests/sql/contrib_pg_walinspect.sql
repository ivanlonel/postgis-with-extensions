-- pg: >=15
-- https://www.postgresql.org/docs/current/pgwalinspect.html
CREATE EXTENSION pg_walinspect;

CREATE TEMPORARY TABLE marks AS SELECT pg_current_wal_lsn() AS before;
CREATE TABLE pwe_logged AS SELECT i FROM generate_series(1, 100) AS i;
CREATE TEMPORARY TABLE marks_after AS SELECT pg_current_wal_lsn() AS after;

SELECT plan(1);
SELECT ok(
	(
		SELECT count(*) > 0
		FROM marks, marks_after, pg_get_wal_records_info(before, after)
		WHERE resource_manager = 'Heap'
	),
	'WAL records are decoded'
);
SELECT * FROM finish(TRUE);
