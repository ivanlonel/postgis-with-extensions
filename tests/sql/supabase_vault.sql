-- preload: supabase_vault
-- https://github.com/supabase/vault
-- Preloaded, Vault reads its root key from the image's pgsodium_getkey script, which generates
-- one in the data directory (the server's working directory).
CREATE EXTENSION supabase_vault;
SELECT vault.create_secret('s3kr3t', 'pwe_secret', 'a test secret');

SELECT plan(3);
SELECT is(
    (
        SELECT decrypted_secret FROM vault.decrypted_secrets
        WHERE name = 'pwe_secret'
    ),
    's3kr3t',
    'secrets decrypt'
);
SELECT isnt(
    (
        SELECT secret FROM vault.secrets
        WHERE name = 'pwe_secret'
    ),
    's3kr3t',
    'and are stored encrypted'
);
SELECT is((pg_stat_file('pgsodium_root.key')).size, 64::bigint, 'the root key is kept in the data directory');
SELECT * FROM finish(TRUE);
