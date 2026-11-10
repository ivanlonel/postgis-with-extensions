-- https://github.com/plproxy/plproxy
CREATE EXTENSION plproxy;

-- A one-partition cluster pointing back at this database.
DO $$
BEGIN
    EXECUTE format(
        'CREATE SERVER testcluster FOREIGN DATA WRAPPER plproxy OPTIONS (p0 %L)',
        format('dbname=%s', current_database())
    );
END
$$;
CREATE USER MAPPING FOR PUBLIC SERVER testcluster;

CREATE TABLE users (username text PRIMARY KEY, email text);
INSERT INTO users VALUES ('alice', 'alice@example.com');

CREATE FUNCTION get_email_local(name text) RETURNS text LANGUAGE sql AS $$
    SELECT email FROM users WHERE username = name
$$;

CREATE FUNCTION get_email(name text) RETURNS text AS $$
    CLUSTER 'testcluster';
    RUN ON hashtext(name);
    TARGET get_email_local;
$$ LANGUAGE plproxy;

CREATE FUNCTION count_users_local() RETURNS SETOF bigint LANGUAGE sql AS $$
    SELECT count(*) FROM users
$$;

CREATE FUNCTION count_users() RETURNS SETOF bigint AS $$
    CLUSTER 'testcluster';
    RUN ON ALL;
    TARGET count_users_local;
$$ LANGUAGE plproxy;

SELECT plan(2);
SELECT is(get_email('alice'), 'alice@example.com', 'calls are proxied to a partition');
SELECT is((SELECT sum(c) FROM count_users() AS c), 1::numeric, 'calls run on every partition');
SELECT * FROM finish(TRUE);
