-- https://github.com/omniti-labs/pg_jobmon
CREATE EXTENSION pg_jobmon CASCADE;  -- requires dblink

SELECT * FROM check_job_status();
