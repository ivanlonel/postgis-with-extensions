-- preload: pg_statement_rollback
-- https://github.com/HexaCluster/pg_statement_rollback
-- Each statement of a transaction gets a savepoint, so a failed one can be undone alone. psql
-- stops at the first error: the transaction runs in another session.
CREATE EXTENSION pg_statement_rollback;
CREATE EXTENSION dblink;
CREATE TABLE kept (id integer);

SELECT dblink_connect('pwe_rollback', format('dbname=%s', current_database()));
-- The image leaves it off: turn it on for that session.
SELECT dblink_exec('pwe_rollback', 'SET pg_statement_rollback.enabled = on');
SELECT dblink_exec('pwe_rollback', 'BEGIN');
SELECT dblink_exec('pwe_rollback', 'INSERT INTO kept VALUES (1)');
SELECT dblink_exec('pwe_rollback', 'INSERT INTO kept VALUES (''not a number'')', FALSE);
SELECT dblink_exec('pwe_rollback', 'ROLLBACK TO "PgSLRAutoSvpt"');
SELECT dblink_exec('pwe_rollback', 'INSERT INTO kept VALUES (2)');
SELECT dblink_exec('pwe_rollback', 'COMMIT');
SELECT dblink_disconnect('pwe_rollback');

SELECT plan(1);
SELECT is(
    ARRAY(
        SELECT id FROM kept
        ORDER BY id
    ),
    ARRAY[1, 2],
    'a failed statement is rolled back alone'
);
SELECT * FROM finish(TRUE);
