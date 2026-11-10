-- https://github.com/pgpartman/pg_partman
CREATE SCHEMA partman;
CREATE EXTENSION pg_partman SCHEMA partman;

CREATE TABLE public.employees (
	id integer,
	fname text,
	lname text,
	dob date NOT NULL,
	joined date NOT NULL
) PARTITION BY RANGE (joined);

CREATE TABLE partman.employees_template (LIKE public.employees);
ALTER TABLE partman.employees_template ADD PRIMARY KEY (id);

SELECT partman.create_parent(
	'public.employees',
	p_control := 'joined',
	p_type := 'range',
	p_interval := '1 year',
	p_template_table := 'partman.employees_template',
	p_premake := 2,
	p_start_partition := '2023-01-01'
);

INSERT INTO public.employees (id, fname, lname, dob, joined)
VALUES (
	generate_series(1, 10000),
	(ARRAY['Oswald', 'Henry', 'Bob', 'Vennie'])[floor(random() * 4 + 1)],
	(ARRAY['Leo', 'Jack', 'Den', 'Daisy', 'Woody'])[floor(random() * 5 + 1)],
	'1995-01-01'::date + trunc(random() * 366 * 3)::int,
	'2023-01-01'::date + trunc(random() * 366 * 3)::int
);

CALL partman.partition_data_proc('public.employees');

UPDATE partman.part_config SET premake = '4'
WHERE parent_table = 'public.employees';
CALL partman.run_maintenance_proc();

SELECT plan(1);
SELECT cmp_ok(
	(
		SELECT count(*) FROM pg_inherits
		WHERE inhparent = 'public.employees'::regclass
	),
	'>=',
	3::bigint,
	'yearly partitions exist'
);
SELECT * FROM finish(TRUE);
