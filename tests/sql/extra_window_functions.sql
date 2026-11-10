-- https://github.com/xocolatl/extra_window_functions
CREATE EXTENSION extra_window_functions;

CREATE TEMP TABLE things (
	part integer NOT NULL,
	ord integer NOT NULL,
	val integer
);

INSERT INTO things (part, ord, val) VALUES
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
(5, 1, NULL),
(5, 2, NULL),
(5, 3, NULL);

CREATE TEMP VIEW windowed AS
SELECT
	part,
	ord,
	lag_ignore_nulls(val) OVER w AS lag_in,
	lead_ignore_nulls(val) OVER w AS lead_in,
	first_value_ignore_nulls(val) OVER w AS fv_in,
	first_value_ignore_nulls(val, -1) OVER w AS fv_in_d,
	last_value_ignore_nulls(val) OVER w AS lv_in,
	nth_value_ignore_nulls(val, 3) OVER w AS nth_in,
	nth_value_from_last(val, 1) OVER w AS nth_fl
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING);

SELECT plan(7);
SELECT is((
	SELECT lag_in FROM windowed
	WHERE part = 4 AND ord = 6
), 80796, 'lag skips nulls');
SELECT is((
	SELECT lead_in FROM windowed
	WHERE part = 4 AND ord = 4
), 41066, 'lead skips nulls');
SELECT is((
	SELECT fv_in FROM windowed
	WHERE part = 4 AND ord = 1
), 49723, 'first_value skips nulls');
SELECT is((
	SELECT fv_in_d FROM windowed
	WHERE part = 5 AND ord = 2
), -1, 'defaults stand in for nothing');
SELECT is((
	SELECT lv_in FROM windowed
	WHERE part = 3 AND ord = 8
), 31143, 'last_value skips nulls');
SELECT is((
	SELECT nth_in FROM windowed
	WHERE part = 4 AND ord = 3
), 80796, 'nth_value skips nulls');
SELECT is((
	SELECT nth_fl FROM windowed
	WHERE part = 3 AND ord = 7
), NULL::integer, 'nth_value from last');
SELECT * FROM finish(TRUE);
