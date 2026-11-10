-- preload: credcheck
-- https://github.com/HexaCluster/credcheck
CREATE EXTENSION credcheck;

BEGIN;
SELECT plan(4);

-- set_config(..., true) is SET LOCAL: the settings end with the transaction.
SELECT set_config('credcheck.username_min_length', '4', TRUE);
SELECT throws_ok(
	$$CREATE USER abc WITH PASSWORD 'pass'$$, NULL, NULL, 'a short user name is rejected'
);
SELECT set_config('credcheck.username_min_length', '1', TRUE);

SELECT set_config('credcheck.password_min_special', '1', TRUE);
SELECT throws_ok(
	$$CREATE USER abcd WITH PASSWORD 'pass'$$, NULL, NULL,
	'a password without special characters is rejected'
);
SELECT set_config('credcheck.password_min_special', '0', TRUE);

SELECT set_config('credcheck.password_contain_username', 'on', TRUE);
SELECT set_config('credcheck.password_ignore_case', 'on', TRUE);
SELECT throws_ok(
	$$CREATE USER "abcd$" WITH PASSWORD 'ABCD$xyz'$$, NULL, NULL,
	'a password containing the user name is rejected'
);
SELECT lives_ok(
	$$CREATE USER pwe_compliant WITH PASSWORD 'x9-Unrelated$secret'$$, 'compliant credentials are accepted'
);

SELECT * FROM finish(TRUE);
ROLLBACK;
