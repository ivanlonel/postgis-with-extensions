-- PoWA repository setup, as in powa-podman's install_all_powa_ext.sql
-- (https://github.com/powa-team/powa-podman). Run with psql on the "postgres" database.
CREATE EXTENSION IF NOT EXISTS hypopg;
CREATE DATABASE powa;
\c powa
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pg_qualstats;
CREATE EXTENSION IF NOT EXISTS pg_stat_kcache;
CREATE EXTENSION IF NOT EXISTS pg_track_settings;
CREATE EXTENSION IF NOT EXISTS pg_wait_sampling;
CREATE EXTENSION IF NOT EXISTS powa;
\c template1
CREATE EXTENSION IF NOT EXISTS hypopg;
