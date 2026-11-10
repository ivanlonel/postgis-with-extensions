-- https://github.com/schmiddy/pg_prioritize
CREATE EXTENSION prioritize;

-- Raising a backend's nice value is allowed; lowering it again isn't, for the non-root postgres user.
SELECT set_backend_priority(pg_backend_pid(), get_backend_priority(pg_backend_pid()) + 5);

SELECT plan(2);
SELECT cmp_ok(get_backend_priority(pg_backend_pid()), '>=', 5, 'backend priorities are lowered');
SELECT throws_ok(
	'SELECT set_backend_priority(pg_backend_pid(), 0)', NULL, NULL, 'raising them back takes root'
);
SELECT * FROM finish(TRUE);
