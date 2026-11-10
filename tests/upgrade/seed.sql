-- Objects created with the previous image, in the "upgrade" database, which
-- tests/upgrade/verify.sql uses with the new one.

CREATE EXTENSION postgis;
CREATE EXTENSION address_standardizer;
CREATE EXTENSION address_standardizer_data_us;
CREATE EXTENSION postgis_tiger_geocoder CASCADE;
-- The tiger geocoder's script puts its schema first in the session's search_path, where the
-- extensions created next would land.
RESET search_path;
CREATE EXTENSION h3_postgis CASCADE;
CREATE EXTENSION pgrouting;
CREATE EXTENSION timescaledb;
CREATE EXTENSION vector;

CREATE TABLE places (id integer PRIMARY KEY, geom GEOMETRY (POINT, 4326));
INSERT INTO places VALUES (1, 'SRID=4326;POINT(-46.63 -23.56)');

CREATE TABLE readings (time timestamptz NOT NULL, value double precision);
SELECT create_hypertable('readings', 'time');
INSERT INTO readings VALUES (now(), 1.0);

CREATE TABLE items (id integer PRIMARY KEY, embedding vector(3));
INSERT INTO items VALUES (1, '[1,2,3]'), (2, '[4,5,6]');
