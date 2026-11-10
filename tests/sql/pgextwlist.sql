-- https://github.com/dimitri/pgextwlist
-- A library, not an extension: loaded in a session, it lets non-superusers create the extensions
-- extwlist.extensions lists, and only those.
CREATE EXTENSION dblink;
CREATE ROLE pwe_extwlist LOGIN;
ALTER ROLE pwe_extwlist SET session_preload_libraries = 'pgextwlist';
-- (The linter can't parse a dotted setting name in ALTER ROLE ... SET.)
DO $$
BEGIN
    EXECUTE 'ALTER ROLE pwe_extwlist SET extwlist.extensions = ''pg_buffercache''';
END
$$;
CREATE FUNCTION as_extwlist_user(statement text) RETURNS text LANGUAGE sql AS $$
    SELECT dblink_exec(format('dbname=%s user=pwe_extwlist', current_database()), statement)
$$;

SELECT plan(2);
SELECT is(as_extwlist_user('CREATE EXTENSION pg_buffercache'), 'CREATE EXTENSION', 'listed extensions can be created');
SELECT matches(
    error_of($$SELECT as_extwlist_user('CREATE EXTENSION pgstattuple')$$),
    'permission denied',
    'others still need a superuser'
);

DROP EXTENSION pg_buffercache;
DROP FUNCTION as_extwlist_user(text);
DROP ROLE pwe_extwlist;
SELECT * FROM finish(TRUE);
