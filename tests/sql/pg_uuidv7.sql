-- https://github.com/fboulnois/pg_uuidv7
CREATE EXTENSION pg_uuidv7;

SELECT plan(1);
SELECT is(substr(uuid_generate_v7()::text, 15, 1), '7', 'UUIDs are version 7');
SELECT * FROM finish(TRUE);
