-- https://github.com/dalibo/emaj
-- Log the changes of a group of tables, then roll them back to a mark.
CREATE EXTENSION emaj CASCADE;

CREATE TABLE accounts (id integer PRIMARY KEY, balance integer NOT NULL);
INSERT INTO accounts VALUES (1, 100), (2, 50);
SELECT emaj.emaj_create_group('pwe_group');
SELECT emaj.emaj_assign_table('public', 'accounts', 'pwe_group');
SELECT emaj.emaj_start_group('pwe_group', 'before');

UPDATE accounts SET balance = balance - 30
WHERE id = 1;
INSERT INTO accounts VALUES (3, 10);
CREATE TEMPORARY TABLE changed AS SELECT array_agg(balance ORDER BY id) AS balances FROM accounts;
SELECT * FROM emaj.emaj_rollback_group('pwe_group', 'before');

SELECT plan(2);
SELECT is((SELECT balances FROM changed), ARRAY[70, 50, 10], 'the changes were applied');
SELECT is(
    ARRAY(
        SELECT balance FROM accounts
        ORDER BY id
    ),
    ARRAY[100, 50],
    'rolling back undoes them'
);

SELECT emaj.emaj_stop_group('pwe_group');
SELECT emaj.emaj_drop_group('pwe_group');
SELECT * FROM finish(TRUE);
