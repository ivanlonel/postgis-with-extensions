-- https://github.com/mpartel/postgres-protobuf
CREATE EXTENSION postgres_protobuf;

-- The schema, as protoc would compile it: a FileDescriptorSet for
-- syntax = "proto3"; package pwe; message Point { int32 x = 1; string label = 2; }
INSERT INTO protobuf_file_descriptor_sets (name, file_descriptor_set) VALUES (
    'default',
    '\x0a450a097077652e70726f746f1203707765222b0a05506f696e74120c0a01781801200128055201'
    '7812140a056c6162656c18022001280952056c6162656c620670726f746f33'::bytea
);
-- Point { x: 42, label: "here" }
CREATE TEMPORARY TABLE points AS SELECT '\x082a120468657265'::bytea AS point;

SELECT plan(2);
SELECT is((SELECT protobuf_query('pwe.Point:x', point) FROM points), '42', 'fields are selected by name');
SELECT is(
    (SELECT protobuf_to_json_text('pwe.Point', point)::jsonb FROM points),
    '{"x": 42, "label": "here"}'::jsonb,
    'messages convert to JSON'
);
SELECT * FROM finish(TRUE);
