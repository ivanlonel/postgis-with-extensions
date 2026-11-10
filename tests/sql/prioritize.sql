-- https://github.com/schmiddy/pg_prioritize
CREATE EXTENSION prioritize;

SELECT get_backend_priority(pg_backend_pid());
