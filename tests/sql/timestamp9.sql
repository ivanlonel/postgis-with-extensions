-- https://github.com/fvannee/timestamp9
CREATE EXTENSION timestamp9;

CREATE TABLE events (at timestamp9 PRIMARY KEY);
INSERT INTO events VALUES
('2019-09-19 08:30:05.123456789 +0200'),
('2019-09-19 08:30:05.123456788 +0200'),
('2019-09-19 08:30:05.123456790 +0200');

SELECT plan(4);
SELECT is((1::bigint::timestamp9)::bigint, 1::bigint, 'nanosecond timestamps round-trip');
SELECT is(
    '1970-01-01 00:00:00.000000001 +0000'::timestamp9::bigint,
    1::bigint,
    'nanoseconds are parsed'
);
SELECT ok(
    '2019-09-19 08:30:05.123456789 +0200'::timestamp9 > '2019-09-19 08:30:05.123456788 +0200'::timestamp9,
    'timestamps compare to the nanosecond'
);
SELECT is(
    (SELECT max(at::bigint) - min(at::bigint) FROM events),
    2::bigint,
    'timestamps are indexed and aggregated'
);
SELECT * FROM finish(TRUE);
