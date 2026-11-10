-- https://github.com/cybertec-postgresql/pg_pwhash
CREATE EXTENSION pg_pwhash;

CREATE TABLE users AS
SELECT
	'alice' AS name,
	pwhash_crypt('correct horse', pwhash_gen_salt('argon2id')) AS argon2,
	pwhash_scrypt_crypt('correct horse', pwhash_gen_salt('scrypt')) AS scrypt,
	pwhash_yescrypt_crypt('correct horse', pwhash_gen_salt('yescrypt')) AS yescrypt;

SELECT plan(5);
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
	(SELECT pwhash_scrypt_crypt('correct horse', scrypt) FROM users), (SELECT scrypt FROM users), 'scrypt hashes verify'
);
SELECT is(
	(SELECT pwhash_yescrypt_crypt('correct horse', yescrypt) FROM users),
	(SELECT yescrypt FROM users),
	'yescrypt hashes verify'
);
SELECT * FROM finish(TRUE);
