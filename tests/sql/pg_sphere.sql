-- https://github.com/postgrespro/pgsphere
CREATE EXTENSION pg_sphere;

SELECT set_sphere_output('DEG');
SELECT npoints(spoly '{(10d,0d),(10d,1d),(15d,0d),(5d,-5d)}');
SELECT area(spoly '{(0d,0d),(0d,90d),(90d,0d)}') / (4.0 * pi());
SELECT '<(180d,-90d),1.0d>'::scircle ~ spoly '{(0d,-89d),(90d,-89d),(180d,-89d),(270d,-89d)}';

SELECT set_sphere_output('DMS');
SELECT 180.0 * dist('<( 0h 2m 30s , 10d 0m 0s), 0.1d>'::scircle, '<( 0h 2m 30s , -10d 0m 0s),0.1d>'::scircle) / pi();
SELECT scircle('(0d,-90d)'::spoint);

SELECT set_sphere_output('RAD');
SELECT dist('( 0h 2m 30s , 95d 0m 0s)'::spoint, '( 12h 2m 30s , 85d 0m 0s)'::spoint);
SELECT long('(24h 2m 30s ,-85d 0m 0s)'::spoint);
SELECT lat('( 0h 2m 30s ,85d 0m 0s)'::spoint);
SELECT spoint(7.28318530717958623, 0.00);

SELECT plan(1);
SELECT is(npoints(spoly '{(10d,0d),(10d,1d),(15d,0d),(5d,-5d)}'), 4, 'polygons have their points');
SELECT * FROM finish(TRUE);
