-- Helpers installed in every database the test scripts run in (see tests/test_sql.py).

-- Poll a boolean query until it returns true or the timeout passes, and tell whether it did.
-- Each poll takes a fresh snapshot, so it sees what other sessions (such as workers) commit.
CREATE OR REPLACE FUNCTION wait_until(condition text, timeout interval DEFAULT '60 seconds')
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
	deadline timestamptz := clock_timestamp() + timeout;
	satisfied boolean;
BEGIN
	LOOP
		EXECUTE condition INTO satisfied;
		IF satisfied THEN
			RETURN TRUE;
		ELSIF clock_timestamp() > deadline THEN
			RETURN FALSE;
		END IF;
		PERFORM pg_sleep(0.2);
	END LOOP;
END;
$$;

-- The plan of a query, to check that it uses an index (or a custom scan).
CREATE OR REPLACE FUNCTION plan_of(query text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
	line text;
	plan text := '';
BEGIN
	FOR line IN EXECUTE 'EXPLAIN (COSTS OFF) ' || query LOOP
		plan := plan || line || E'\n';
	END LOOP;
	RETURN plan;
END;
$$;
