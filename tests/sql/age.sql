-- https://github.com/apache/age
CREATE EXTENSION age;
LOAD 'age';

SET search_path = ag_catalog, "$user", public;

SELECT create_graph('graph_name');

-- create vertices
SELECT * FROM cypher('graph_name', $$CREATE (:label {property:"Node A"})$$) AS (v agtype);
SELECT * FROM cypher('graph_name', $$CREATE (:label {property:"Node B"})$$) AS (v agtype);

-- create an edge between two nodes and set its properties
SELECT * FROM cypher(
	'graph_name',
	$$
		MATCH (a:label), (b:label)
		WHERE a.property = 'Node A' AND b.property = 'Node B'
		CREATE (a)-[e:RELTYPE {property:a.property + '<->' + b.property}]->(b)
		RETURN e
	$$
) AS (e agtype);

-- query the connected nodes
SELECT * FROM cypher(
	'graph_name',
	$$
		MATCH (V)-[R]-(V2)
		RETURN V,R,V2
	$$
) AS (V agtype, R agtype, V2 agtype);
