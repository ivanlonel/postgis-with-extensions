-- https://github.com/arkhipov/temporal_tables
CREATE EXTENSION temporal_tables;

CREATE TABLE employees (
	name text NOT NULL PRIMARY KEY,
	department text,
	salary numeric(20, 2),
	sys_period tstzrange NOT NULL
);
CREATE TABLE employees_history (LIKE employees);

CREATE TRIGGER versioning_trigger
BEFORE INSERT OR UPDATE OR DELETE ON employees
FOR EACH ROW EXECUTE PROCEDURE versioning('sys_period', 'employees_history', TRUE);

INSERT INTO employees (name, department, salary) VALUES
('Bernard Marx', 'Hatchery and Conditioning Centre', 10000),
('Lenina Crowne', 'Hatchery and Conditioning Centre', 7000),
('Helmholtz Watson', 'College of Emotional Engineering', 18500);

SELECT pg_sleep(0.1);

UPDATE employees SET salary = 11200
WHERE name = 'Bernard Marx';
DELETE FROM employees
WHERE name = 'Helmholtz Watson';

SELECT plan(4);
SELECT is((SELECT count(*) FROM employees_history), 2::bigint, 'history keeps the old rows');
SELECT is(
	(
		SELECT salary FROM employees_history
		WHERE name = 'Bernard Marx'
	),
	10000::numeric(20, 2),
	'with their old values'
);
SELECT ok(
	(SELECT bool_and(NOT upper_inf(sys_period)) FROM employees_history),
	'history rows have an end'
);
SELECT ok(
	(
		SELECT lower(e.sys_period) = upper(h.sys_period)
		FROM employees AS e
		INNER JOIN employees_history AS h ON e.name = h.name
		WHERE e.name = 'Bernard Marx'
	),
	'versions follow one another without gaps'
);
SELECT * FROM finish(TRUE);
