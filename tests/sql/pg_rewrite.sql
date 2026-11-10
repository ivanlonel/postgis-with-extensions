-- preload: pg_rewrite
-- https://github.com/cybertec-postgresql/pg_rewrite
CREATE EXTENSION pg_rewrite;

-- Turn a plain table into a partitioned one, rows and all, while it stays usable.
CREATE TABLE measurement (id integer PRIMARY KEY, city text, logdate date NOT NULL);
INSERT INTO measurement
SELECT
	i,
	'city ' || (i % 10),
	'2024-01-01'::date + (i % 365)
FROM generate_series(1, 1000) AS i;

CREATE TABLE measurement_aux (id integer, city text, logdate date NOT NULL) PARTITION BY RANGE (id);
CREATE TABLE measurement_aux_low PARTITION OF measurement_aux FOR VALUES FROM (minvalue) TO (501);
CREATE TABLE measurement_aux_high PARTITION OF measurement_aux FOR VALUES FROM (501) TO (maxvalue);
ALTER TABLE measurement_aux ADD PRIMARY KEY (id);

SELECT partition_table('measurement', 'measurement_aux', 'measurement_old');

SELECT plan(3);
SELECT is(
	(
		SELECT relkind::text FROM pg_class
		WHERE oid = 'measurement'::regclass
	),
	'p',
	'the table is now partitioned'
);
SELECT is((SELECT count(*) FROM measurement), 1000::bigint, 'its rows are kept');
SELECT is((SELECT count(*) FROM measurement_aux_high), 500::bigint, 'and routed to the partitions');
SELECT * FROM finish(TRUE);
