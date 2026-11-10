-- https://github.com/postgrespro/pgsphere
CREATE EXTENSION pg_sphere;

CREATE TABLE stars (id integer PRIMARY KEY, position spoint);
INSERT INTO stars
SELECT
    i,
    spoint(radians(i % 360), radians((i / 360) - 45))
FROM generate_series(0, 32399) AS i;
CREATE INDEX stars_position_idx ON stars USING gist (position);
ANALYZE stars;

SELECT plan(6);
SELECT is(npoints(spoly '{(10d,0d),(10d,1d),(15d,0d),(5d,-5d)}'), 4, 'polygons have their points');
SELECT is(
    round((area(spoly '{(0d,0d),(0d,90d),(90d,0d)}') / (4 * pi()))::numeric, 6),
    0.125,
    'an octant is an eighth of the sphere'
);
SELECT is(
    round(dist('(0d,0d)'::spoint, '(90d,0d)'::spoint)::numeric, 6),
    round((pi() / 2)::numeric, 6),
    'distances are great circles'
);
SELECT ok(
    '(0.5d,0.5d)'::spoint @ spoly '{(0d,0d),(0d,1d),(1d,1d),(1d,0d)}',
    'points are located in polygons'
);
SELECT is(
    (
        SELECT count(*) FROM stars
        WHERE position @ scircle '<(10d,0d),1.5d>'
    ),
    9::bigint,
    'circle searches find the points'
);
SELECT matches(
    plan_of($$SELECT * FROM stars WHERE position @ scircle '<(10d,0d),1.5d>'$$),
    'stars_position_idx',
    'circle searches use the GiST index'
);
SELECT * FROM finish(TRUE);
