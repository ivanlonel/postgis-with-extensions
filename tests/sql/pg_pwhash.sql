-- https://github.com/cybertec-postgresql/pg_pwhash
CREATE EXTENSION pg_pwhash;

SELECT plan(1);
SELECT is(pwhash_crypt('password', hashed.hash), hashed.hash, 'argon2id hashes verify')
FROM (SELECT pwhash_crypt('password', pwhash_gen_salt('argon2id')) AS hash) AS hashed;
SELECT * FROM finish(TRUE);
