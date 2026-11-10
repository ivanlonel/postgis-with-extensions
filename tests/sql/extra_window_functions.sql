-- https://github.com/xocolatl/extra_window_functions
CREATE EXTENSION extra_window_functions;

CREATE TEMP TABLE things (
	part integer NOT NULL,
	ord integer NOT NULL,
	val integer
);

INSERT INTO things (part, ord, val) VALUES
(1, 1, 64664),
(1, 2, 8779),
(1, 3, 14005),
(1, 4, 57699),
(1, 5, 98842),
(1, 6, 88563),
(1, 7, 70453),
(1, 8, 82824),
(1, 9, 62453),
(2, 1, NULL),
(2, 2, 51714),
(2, 3, 17096),
(2, 4, 41605),
(2, 5, 15366),
(2, 6, 87359),
(2, 7, 98990),
(2, 8, 34982),
(2, 9, 3343),
(3, 1, 21903),
(3, 2, 24605),
(3, 3, 6242),
(3, 4, 24947),
(3, 5, 79535),
(3, 6, 66903),
(3, 7, 42269),
(3, 8, 31143),
(3, 9, NULL),
(4, 1, NULL),
(4, 2, 49723),
(4, 3, 23958),
(4, 4, 80796),
(4, 5, NULL),
(4, 6, 41066),
(4, 7, 72991),
(4, 8, 33734),
(4, 9, NULL),
(5, 1, NULL),
(5, 2, NULL),
(5, 3, NULL),
(5, 4, NULL),
(5, 5, NULL),
(5, 6, NULL),
(5, 7, NULL),
(5, 8, NULL),
(5, 9, NULL);

/* FLIP_FLOP */
SELECT
	part,
	ord,
	val,
	flip_flop(val % 2 = 0) OVER w AS flip_flop_1,
	flip_flop(val % 2 = 0, val % 2 = 1) OVER w AS flip_flop_2
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

/* LAG */
SELECT
	part,
	ord,
	val,
	lag(val) OVER w AS lag,
	lag_ignore_nulls(val) OVER w AS lag_in,
	lag_ignore_nulls(val, 2) OVER w AS lag_in_off,
	lag_ignore_nulls(val, 2, -9999999) OVER w AS lag_in_off_d
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

/* LEAD */
SELECT
	part,
	ord,
	val,
	lead(val) OVER w AS lead,
	lead_ignore_nulls(val) OVER w AS lead_in,
	lead_ignore_nulls(val, 2) OVER w AS lead_in_off,
	lead_ignore_nulls(val, 2, 9999999) OVER w AS lead_in_off_d
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

/* FIRST_VALUE */
SELECT
	part,
	ord,
	val,
	first_value(val) OVER w AS fv,
	first_value_ignore_nulls(val) OVER w AS fv_in,
	first_value_ignore_nulls(val, 9999999) OVER w AS fv_in_d
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

/* LAST_VALUE */
SELECT
	part,
	ord,
	val,
	last_value(val) OVER w AS lv,
	last_value_ignore_nulls(val) OVER w AS lv_in,
	last_value_ignore_nulls(val, -9999999) OVER w AS lv_in_d
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

/* NTH_VALUE */
SELECT
	part,
	ord,
	val,
	nth_value(val, 3) OVER w AS nth,
	nth_value_ignore_nulls(val, 3) OVER w AS nth_in
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

SELECT
	part,
	ord,
	val,
	nth_value(val, 3) OVER w AS nth,
	nth_value_from_last(val, 3) OVER w AS nth_fl
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

SELECT
	part,
	ord,
	val,
	nth_value_from_last(val, 3) OVER w AS nth_fl,
	nth_value_from_last_ignore_nulls(val, 3) OVER w AS nth_fl_in
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;
