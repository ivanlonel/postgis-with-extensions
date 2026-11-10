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
