-- https://github.com/cybertec-postgresql/pg_pwhash
CREATE EXTENSION pg_pwhash;

-- pwhash_crypt() picks the algorithm from the salt: argon2id, scrypt through libscrypt, and
-- scrypt through the system's crypt() ($7$).
CREATE TABLE users AS
SELECT
    'alice' AS name,
    pwhash_crypt('correct horse', pwhash_gen_salt('argon2id')) AS argon2,
    pwhash_crypt('correct horse', pwhash_gen_salt('scrypt')) AS scrypt,
    pwhash_crypt('correct horse', pwhash_gen_salt('$7$')) AS crypt_scrypt;

SELECT plan(6);
SELECT is(
    (SELECT pwhash_crypt('correct horse', argon2) FROM users),
    (SELECT argon2 FROM users),
    'argon2id hashes verify'
);
SELECT isnt(
    (SELECT pwhash_crypt('wrong horse', argon2) FROM users),
    (SELECT argon2 FROM users),
    'wrong passwords fail'
);
SELECT matches((SELECT argon2 FROM users), '^\$argon2id\$', 'hashes say what they are');
SELECT is(
    (SELECT pwhash_crypt('correct horse', scrypt) FROM users), (SELECT scrypt FROM users), 'scrypt hashes verify'
);
SELECT matches((SELECT scrypt FROM users), '^\$scrypt\$', 'scrypt hashes come from libscrypt');
SELECT is(
    (SELECT pwhash_crypt('correct horse', crypt_scrypt) FROM users),
    (SELECT crypt_scrypt FROM users),
    'crypt() scrypt hashes verify'
);
SELECT * FROM finish(TRUE);
