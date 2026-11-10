-- https://github.com/MobilityDB/MobilityDB
CREATE EXTENSION mobilitydb CASCADE;  -- requires postgis

SELECT bigintset '{1,2,3}';
SELECT asText(floatset '{1.12345678, 2.123456789}', 6);
SELECT set(ARRAY[date '2000-01-01', '2000-01-02', '2000-01-03']);
SELECT set(ARRAY[timestamptz '2000-01-01', '2000-01-02', '2000-01-03']);
SELECT set(ARRAY[geometry 'Point(1 1)', 'Point(2 2)', 'Point(3 3)']);
SELECT memSize(dateset '{2000-01-01, 2000-01-02, 2000-01-03}');
SELECT span(tstzset '{2000-01-01, 2000-01-02, 2000-01-03}');
SELECT shiftScale(intset '{1}', 4, 4);

SELECT asText(floatspan '[1.12345678, 2.123456789]', 6);
SELECT span(timestamptz '2000-01-01', '2000-01-02');
SELECT span(timestamptz '2000-01-01', '2000-01-01', TRUE, TRUE);
SELECT range(datespan '[2000-01-01,2000-01-02)');
SELECT span(daterange '(2000-01-01,2000-01-03)');
SELECT span(date '2000-01-01');
SELECT date '2000-01-01'::datespan;
SELECT range(tstzspan '[2000-01-01,2000-01-02)');
SELECT span(tstzrange '(2000-01-01,2000-01-02)');
SELECT span(timestamptz '2000-01-01');
SELECT timestamptz '2000-01-01'::tstzspan;
SELECT intspan '[1,2]';
SELECT intspan '(1,2]';

SELECT bigintspanset '{[1,2),[3,4),[5,6)}';
SELECT
	spanset_cmp(
		datespanset '{[2000-01-01,2000-01-01]}',
		datespanset '{[2000-01-01,2000-01-02),[2000-01-03,2000-01-04),[2000-01-05,2000-01-06)}'
	);
SELECT round(floatspanset '{[1.12345,2.12345),[3.12345,4.12345),[5.12345,6.12345)}', 2);
SELECT shift(intspanset '{[1,2),[3,4),[5,6)}', 2);
SELECT
	shiftScale(
		tstzspanset '{[2000-01-01,2000-01-02),(2000-01-03,2000-01-04),(2000-01-05,2000-01-06)}',
		'5 min',
		'1 hour'
	);
