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

SELECT plan(1);
SELECT is((SELECT count(*) FROM employees_history), 2::bigint, 'history keeps the old rows');
SELECT * FROM finish(TRUE);
