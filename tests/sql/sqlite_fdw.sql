-- pg: <=17
-- https://github.com/pgspider/sqlite_fdw
CREATE EXTENSION sqlite_fdw;
CREATE EXTENSION plpython3u;

-- Create the SQLite database with Python's sqlite3 module.
DO LANGUAGE plpython3u $$
import sqlite3
connection = sqlite3.connect("/tmp/sqlite_fdw_test.db")
connection.execute("DROP TABLE IF EXISTS t1")
connection.execute("CREATE TABLE t1 (id integer PRIMARY KEY, name text, price real)")
connection.executemany("INSERT INTO t1 VALUES (?, ?, ?)", [(1, "apple", 1.5), (2, "pear", 2.5)])
connection.commit()
connection.close()
$$;

CREATE SERVER sqlite_server FOREIGN DATA WRAPPER sqlite_fdw
OPTIONS (database '/tmp/sqlite_fdw_test.db');
CREATE FOREIGN TABLE t1 (id integer OPTIONS (key 'true'), name text, price float8)
SERVER sqlite_server OPTIONS (table 't1');
CREATE SCHEMA imported;
IMPORT FOREIGN SCHEMA public FROM SERVER sqlite_server INTO imported;

SELECT plan(5);
SELECT is((SELECT string_agg(name, ',' ORDER BY id) FROM t1), 'apple,pear', 'SQLite rows are read');
SELECT is((SELECT sum(price) FROM t1), 4::float8, 'aggregates are computed');
INSERT INTO t1 VALUES (3, 'plum', 3);
UPDATE t1 SET price = 2
WHERE name = 'pear';
DELETE FROM t1
WHERE id = 1;
SELECT is((SELECT string_agg(name, ',' ORDER BY id) FROM t1), 'pear,plum', 'SQLite rows are written');
SELECT is((SELECT sum(price) FROM t1), 5::float8, 'SQLite rows are updated');
SELECT is((SELECT count(*) FROM imported.t1), 2::bigint, 'foreign schemas are imported');
SELECT * FROM finish(TRUE);
