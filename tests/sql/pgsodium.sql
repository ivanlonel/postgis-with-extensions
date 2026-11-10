-- https://github.com/michelp/pgsodium
-- libsodium's primitives work without preloading (which adds the server-key functions).
CREATE EXTENSION pgsodium;

CREATE TEMPORARY TABLE box AS
SELECT
    pgsodium.crypto_secretbox_keygen() AS key,
    pgsodium.crypto_secretbox_noncegen() AS nonce;

SELECT plan(3);
SELECT is(
    encode(pgsodium.crypto_hash_sha256('abc'::bytea), 'hex'),
    'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    'SHA-256 digests'
);
SELECT is(
    (
        SELECT
            convert_from(
                pgsodium.crypto_secretbox_open(pgsodium.crypto_secretbox('message'::bytea, nonce, key), nonce, key),
                'UTF8'
            )
        FROM box
    ),
    'message',
    'secret boxes open with their key'
);
SELECT is(length(pgsodium.randombytes_buf(16)), 16, 'random bytes');
SELECT * FROM finish(TRUE);
