-- https://github.com/apache/age
CREATE EXTENSION age;
LOAD 'age';

SET search_path = ag_catalog, "$user", public;

SELECT create_graph('graph_name');

-- create vertices
SELECT * FROM cypher('graph_name', $$CREATE (:label {property:"Node A"})$$) AS (v agtype);
SELECT * FROM cypher('graph_name', $$CREATE (:label {property:"Node B"})$$) AS (v agtype);
SELECT * FROM cypher('graph_name', $$CREATE (:label {property:"Node C"})$$) AS (v agtype);

-- create edges A->B and B->C, computing a property
SELECT * FROM cypher(
    'graph_name',
    $$
        MATCH (a:label), (b:label)
        WHERE a.property = 'Node A' AND b.property = 'Node B'
        CREATE (a)-[e:RELTYPE {property:a.property + '<->' + b.property}]->(b)
        RETURN e
    $$
) AS (e agtype);
SELECT * FROM cypher(
    'graph_name',
    $$
        MATCH (b:label), (c:label)
        WHERE b.property = 'Node B' AND c.property = 'Node C'
        CREATE (b)-[e:RELTYPE {property:b.property + '<->' + c.property}]->(c)
        RETURN e
    $$
) AS (e agtype);

SELECT plan(3);
SELECT is(
    (SELECT count(*) FROM cypher('graph_name', $$MATCH (v:label) RETURN v$$) AS (v agtype)),
    3::bigint,
    'vertices are created'
);
SELECT is(
    (
        SELECT p::text FROM cypher(
            'graph_name', $$MATCH (:label {property: 'Node A'})-[e:RELTYPE]->() RETURN e.property$$
        ) AS (p agtype)
    ),
    'Node A<->Node B',
    'edge properties are computed'
);
SELECT is(
    (
        SELECT n::text FROM cypher(
            'graph_name', $$MATCH (:label {property: 'Node A'})-[:RELTYPE*2..2]->(c) RETURN c.property$$
        ) AS (n agtype)
    ),
    'Node C',
    'variable-length paths are traversed'
);
SELECT * FROM finish(TRUE);

SELECT drop_graph('graph_name', TRUE);
