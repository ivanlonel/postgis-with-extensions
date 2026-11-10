-- https://github.com/zubkov-andrei/pg_profile
CREATE EXTENSION pg_profile CASCADE;  -- requires dblink and plpgsql

SELECT * FROM show_servers();
