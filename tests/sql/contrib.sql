-- https://www.postgresql.org/docs/current/contrib.html
-- PostgreSQL's own modules, tested upstream: one known answer each proves they're there and work.
CREATE EXTENSION amcheck;
CREATE EXTENSION autoinc;
CREATE EXTENSION bloom;
CREATE EXTENSION btree_gin;
CREATE EXTENSION btree_gist;
CREATE EXTENSION citext;
CREATE EXTENSION cube;
CREATE EXTENSION dblink;
CREATE EXTENSION dict_int;
CREATE EXTENSION dict_xsyn;
CREATE EXTENSION earthdistance;
CREATE EXTENSION file_fdw;
CREATE EXTENSION fuzzystrmatch;
CREATE EXTENSION hstore;
CREATE EXTENSION insert_username;
CREATE EXTENSION intagg;
CREATE EXTENSION intarray;
CREATE EXTENSION isn;
CREATE EXTENSION lo;
CREATE EXTENSION ltree;
CREATE EXTENSION moddatetime;
CREATE EXTENSION pageinspect;
CREATE EXTENSION pg_buffercache;
CREATE EXTENSION pg_freespacemap;
CREATE EXTENSION pg_prewarm;
CREATE EXTENSION pg_surgery;
CREATE EXTENSION pg_trgm;
CREATE EXTENSION pg_visibility;
CREATE EXTENSION pgcrypto;
CREATE EXTENSION pgrowlocks;
CREATE EXTENSION pgstattuple;
CREATE EXTENSION postgres_fdw;
CREATE EXTENSION refint;
CREATE EXTENSION seg;
CREATE EXTENSION sslinfo;
CREATE EXTENSION tablefunc;
CREATE EXTENSION tcn;
CREATE EXTENSION tsm_system_rows;
CREATE EXTENSION tsm_system_time;
CREATE EXTENSION unaccent;
CREATE EXTENSION "uuid-ossp";
CREATE EXTENSION xml2;

-- dict_xsyn's dictionary comes without rules: give it the sample file the module installs.
DO $$
BEGIN
	EXECUTE $sql$ALTER TEXT SEARCH DICTIONARY xsyn (RULES = 'xsyn_sample')$sql$;
END
$$;

CREATE TABLE items (id integer PRIMARY KEY, name text NOT NULL, tags integer[], author text, modified timestamptz);
INSERT INTO items (id, name, tags)
SELECT
	i,
	'item ' || i,
	ARRAY[i % 5, i % 7]
FROM generate_series(1, 1000) AS i;
VACUUM (ANALYZE) items;

-- Triggers from autoinc, insert_username, moddatetime, refint, tcn and lo.
CREATE SEQUENCE numbered_seq;
CREATE TABLE numbered (id integer, name text);
CREATE TRIGGER numbered_autoinc BEFORE INSERT ON numbered
FOR EACH ROW EXECUTE PROCEDURE autoinc(id, numbered_seq);
INSERT INTO numbered VALUES (0, 'first');
CREATE TRIGGER items_author BEFORE INSERT OR UPDATE ON items
FOR EACH ROW EXECUTE PROCEDURE insert_username(author);
CREATE TRIGGER items_modified BEFORE UPDATE ON items
FOR EACH ROW EXECUTE PROCEDURE moddatetime(modified);
UPDATE items SET name = 'renamed'
WHERE id = 1;
CREATE TABLE children (id integer, item_id integer);
CREATE TRIGGER children_item BEFORE INSERT OR UPDATE ON children
FOR EACH ROW EXECUTE PROCEDURE check_primary_key('item_id', 'items', 'id');
CREATE TRIGGER items_notify AFTER INSERT ON items
FOR EACH ROW EXECUTE PROCEDURE triggered_change_notification();
CREATE TABLE images (id integer, raster lo);
CREATE TRIGGER images_raster BEFORE UPDATE OR DELETE ON images
FOR EACH ROW EXECUTE PROCEDURE lo_manage(raster);
INSERT INTO images VALUES (1, lo_from_bytea(0, '\x0102'));
CREATE TEMPORARY TABLE image_oid AS SELECT raster::oid AS oid FROM images;
DELETE FROM images;

-- Loopback foreign tables (postgres_fdw, dblink) and a CSV one (file_fdw).
DO $$
BEGIN
	EXECUTE format(
		'CREATE SERVER loopback FOREIGN DATA WRAPPER postgres_fdw OPTIONS (dbname %L)', current_database()
	);
END
$$;
CREATE USER MAPPING FOR current_user SERVER loopback;
CREATE FOREIGN TABLE remote_items (id integer, name text) SERVER loopback OPTIONS (table_name 'items');
COPY (SELECT
	id,
	name
FROM items
WHERE id <= 10) TO '/tmp/contrib_items.csv' WITH (FORMAT csv);
CREATE SERVER files FOREIGN DATA WRAPPER file_fdw;
CREATE FOREIGN TABLE file_items (id integer, name text) SERVER files
OPTIONS (filename '/tmp/contrib_items.csv', format 'csv');

CREATE INDEX items_bloom_idx ON items USING bloom (id, length(name));
CREATE INDEX items_gin_idx ON items USING gin (id);
CREATE INDEX items_trgm_idx ON items USING gin (name gin_trgm_ops);
CREATE TABLE bookings (room integer, during tsrange, EXCLUDE USING gist (room WITH =, during WITH &&));
INSERT INTO bookings VALUES (1, '[2024-01-01, 2024-01-05)');

SELECT plan(48);
SELECT lives_ok($$SELECT bt_index_check('items_pkey')$$, 'amcheck checks B-tree indexes');
SELECT is((SELECT id FROM numbered), 1, 'autoinc numbers rows from a sequence');
SELECT is((
	SELECT count(*) FROM items
	WHERE id = 7 AND length(name) = 6
), 1::bigint, 'bloom indexes are built');
SELECT is((
	SELECT count(*) FROM items
	WHERE id = 7
), 1::bigint, 'btree_gin indexes scalars');
SELECT throws_ok(
	$$INSERT INTO bookings VALUES (1, '[2024-01-03, 2024-01-04)')$$, '23P01', NULL, 'btree_gist enables exclusion'
);
SELECT ok('ABC'::citext = 'abc', 'citext compares case-insensitively');
SELECT is(cube_distance('(0,0)'::cube, '(3,4)'::cube), 5::float8, 'cube measures distances');
SELECT is(
	(SELECT x FROM dblink(format('dbname=%s', current_database()), 'SELECT 42') AS t (x integer)),
	42,
	'dblink queries other databases'
);
SELECT is(ts_lexize('intdict', '12345678'), ARRAY['123456'], 'dict_int truncates numbers');
SELECT is(ts_lexize('xsyn', 'supernova'), ARRAY['supernova', 'sn', 'sne', '1987a'], 'dict_xsyn expands synonyms');
SELECT ok(
	earth_distance(ll_to_earth(51.5074, -0.1278), ll_to_earth(48.8566, 2.3522)) BETWEEN 340000 AND 347000,
	'earthdistance measures great circles'
);
SELECT is((SELECT count(*) FROM file_items), 10::bigint, 'file_fdw reads files');
SELECT is(levenshtein('kitten', 'sitting'), 3, 'fuzzystrmatch computes edit distances');
SELECT is(soundex('Robert'), 'R163', 'fuzzystrmatch encodes sounds');
SELECT is('a=>1, b=>2'::hstore -> 'b', '2', 'hstore stores key/value pairs');
SELECT is((
	SELECT author FROM items
	WHERE id = 1
), current_user::text, 'insert_username stamps the user');
SELECT is(
	(SELECT int_array_aggregate(i) FROM generate_series(1, 3) AS i), ARRAY[1, 2, 3], 'intagg aggregates integers'
);
SELECT is('{1,2,3}'::integer[] & '{2,3,4}'::integer[], ARRAY[2, 3], 'intarray intersects arrays');
SELECT is(sort('{3,1,2}'::integer[]), ARRAY[1, 2, 3], 'intarray sorts arrays');
SELECT ok(is_valid('978-0-306-40615-7'::isbn13), 'isn validates ISBNs');
SELECT throws_ok($$SELECT '978-0-306-40615-8'::isbn13$$, NULL, NULL, 'isn rejects bad check digits');
SELECT is(
	(
		SELECT count(*) FROM pg_largeobject_metadata
		WHERE oid = (SELECT oid FROM image_oid)
	),
	0::bigint,
	'lo_manage unlinks orphaned large objects'
);
SELECT ok('Top.Science.Astronomy'::ltree <@ 'Top.Science', 'ltree matches subtrees');
SELECT is(nlevel('Top.Science.Astronomy'::ltree), 3, 'ltree counts levels');
SELECT isnt((
	SELECT modified FROM items
	WHERE id = 1
), NULL, 'moddatetime stamps updates');
SELECT cmp_ok(
	(SELECT count(*) FROM heap_page_items(get_raw_page('items', 0))), '>', 0::bigint, 'pageinspect reads pages'
);
SELECT ok((SELECT count(*) > 0 FROM pg_buffercache), 'pg_buffercache lists buffers');
SELECT ok((SELECT count(*) > 0 FROM pg_freespace('items')), 'pg_freespacemap reads the free space map');
SELECT cmp_ok(pg_prewarm('items'), '>', 0::bigint, 'pg_prewarm loads relations');
-- (0,2) holds a row nothing has touched since it was written.
SELECT lives_ok(
	$$SELECT heap_force_freeze('items'::regclass, ARRAY['(0,2)']::tid[])$$, 'pg_surgery freezes tuples'
);
SELECT ok(similarity('word', 'words') > 0.5, 'pg_trgm measures similarity');
SELECT is((
	SELECT count(*) FROM items
	WHERE name LIKE '%tem 99%'
), 11::bigint, 'pg_trgm indexes LIKE searches');
-- VACUUM only marks pages all-visible once no older snapshot remains, which a background worker can
-- hold: retry it, from another session (VACUUM can't run in a function).
SELECT ok(
	wait_until(
		$$
			SELECT dblink_exec(format('dbname=%s', current_database()), 'VACUUM items') = 'VACUUM'
				AND (SELECT all_visible > 0 FROM pg_visibility_map_summary('items'))
		$$
	),
	'pg_visibility reads the visibility map'
);
SELECT is(
	encode(digest('abc', 'sha256'), 'hex'),
	'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
	'pgcrypto hashes'
);
SELECT is(pgp_sym_decrypt(pgp_sym_encrypt('secret', 'key'), 'key'), 'secret', 'pgcrypto encrypts');
SELECT is_empty($$SELECT * FROM pgrowlocks('items')$$, 'pgrowlocks finds no locked row');
SELECT is((pgstattuple('items')).tuple_count, 1000::bigint, 'pgstattuple counts tuples');
SELECT is((SELECT count(*) FROM remote_items), 1000::bigint, 'postgres_fdw reads remote tables');
SELECT throws_ok($$INSERT INTO children VALUES (1, 99999)$$, NULL, NULL, 'refint checks references');
SELECT ok('1.5 .. 2.5'::seg @> '2'::seg, 'seg contains values');
SELECT is(ssl_is_used(), FALSE, 'sslinfo reports the connection');
SELECT is(
	(
		SELECT y FROM crosstab(
			$$SELECT * FROM (VALUES ('a', 'x', 1), ('a', 'y', 2)) AS t (row_name, cat, value) ORDER BY 1, 2$$
		) AS ct (row_name text, x integer, y integer)
	),
	2,
	'tablefunc pivots rows'
);
SELECT results_eq(
	'SELECT count(*) FROM items TABLESAMPLE system_rows (5)', ARRAY[5::bigint], 'tsm_system_rows samples rows'
);
SELECT lives_ok('SELECT count(*) FROM items TABLESAMPLE system_time (1000)', 'tsm_system_time samples for a time');
SELECT is(unaccent('Hôtel'), 'Hotel', 'unaccent strips accents');
SELECT is(substr(uuid_generate_v4()::text, 15, 1), '4', 'uuid-ossp generates version 4 UUIDs');
SELECT is(xpath_string('<a><b>x</b></a>', '/a/b'), 'x', 'xml2 evaluates XPath');
-- Last, as it adds a row: tcn notifies listeners (none here) of the change.
SELECT lives_ok($$INSERT INTO items (id, name) VALUES (1001, 'notified')$$, 'tcn notifies of changes');
SELECT * FROM finish(TRUE);
