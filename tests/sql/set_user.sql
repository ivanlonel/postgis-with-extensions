-- preload: set_user
-- https://github.com/pgaudit/set_user
CREATE EXTENSION set_user;

-- pgTAP can't record results while another user is current, so assert with a plain function.
CREATE FUNCTION assert_that(condition boolean, description text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
	IF NOT condition THEN
		RAISE EXCEPTION 'assertion failed: %', description;
	END IF;
END
$$;

SELECT set_user('pg_monitor');
SELECT assert_that(current_user = 'pg_monitor', 'set_user switches the current user');
SELECT reset_user();
SELECT assert_that(current_user = session_user, 'reset_user switches back');
