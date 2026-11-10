-- preload: pg_savior
-- https://github.com/viggy28/pg_savior
CREATE EXTENSION pg_savior;
CREATE TABLE precious (id integer PRIMARY KEY);
INSERT INTO precious SELECT generate_series(1, 10);

-- The image leaves it off: turn it on for this session.
SELECT set_config('pg_savior.enabled', 'on', FALSE);
SELECT plan(3);
SELECT throws_like('DELETE FROM precious', '%WHERE%', 'DELETE without WHERE is blocked');
SELECT throws_like('UPDATE precious SET id = id + 100', '%WHERE%', 'so is UPDATE without WHERE');
SELECT lives_ok('DELETE FROM precious WHERE id = 1', 'qualified statements run');
SELECT * FROM finish(TRUE);
