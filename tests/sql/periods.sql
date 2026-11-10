-- https://github.com/xocolatl/periods
CREATE EXTENSION periods CASCADE;  -- requires btree_gist

-- System versioning: the table keeps its past.
CREATE TABLE prices (product text PRIMARY KEY, price numeric);
SELECT periods.add_system_time_period('prices');
SELECT periods.add_system_versioning('prices');
INSERT INTO prices VALUES ('tea', 3);
CREATE TEMPORARY TABLE marks AS SELECT clock_timestamp() AS before_change;
UPDATE prices SET price = 4
WHERE product = 'tea';

-- Application time: bookings of a room can't overlap.
CREATE TABLE bookings (room integer, starts date, ends date);
SELECT periods.add_period('bookings', 'during', 'starts', 'ends');
SELECT periods.add_unique_key('bookings', ARRAY['room'], 'during');
INSERT INTO bookings VALUES (1, '2024-01-01', '2024-01-05');

SELECT plan(4);
SELECT is((
    SELECT price FROM prices_history
    WHERE product = 'tea'
), 3::numeric, 'old versions are kept');
SELECT is(
    (SELECT price FROM marks, prices__as_of(before_change)),
    3::numeric,
    'the past can be queried'
);
SELECT lives_ok($$INSERT INTO bookings VALUES (1, '2024-01-05', '2024-01-07')$$, 'adjacent periods are fine');
SELECT throws_ok(
    $$INSERT INTO bookings VALUES (1, '2024-01-03', '2024-01-04')$$, '23P01', NULL, 'overlapping periods are rejected'
);
SELECT * FROM finish(TRUE);
