-- https://github.com/orafce/orafce
CREATE EXTENSION orafce;

SELECT dbms_output.enable(1000);
SELECT dbms_output.put_line('hello from dbms_output');

SELECT plan(5);
SELECT is(
	oracle.add_months(oracle.date '2021-05-31 10:12:12', 1)::text,
	'2021-06-30 10:12:12',
	'add_months moves to the last day of the month'
);
SELECT is(oracle.last_day(date '2024-02-10'), date '2024-02-29', 'last_day knows leap years');
SELECT is(
	oracle.months_between(date '2024-03-31', date '2024-01-31'), 2::numeric, 'months_between counts months'
);
SELECT is(plvstr.rvrs('abc', 1, 3), 'cba', 'PLVstr reverses strings');
SELECT is((SELECT line FROM dbms_output.get_line()), 'hello from dbms_output', 'DBMS_OUTPUT buffers lines');
SELECT * FROM finish(TRUE);
