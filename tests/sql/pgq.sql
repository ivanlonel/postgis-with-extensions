-- https://github.com/pgq/pgq
-- https://github.com/pgq/pgq-node
CREATE EXTENSION pgq;
CREATE EXTENSION pgq_node;

SELECT pgq.create_queue('testqueue1');
SELECT * FROM pgq_node.get_queue_locations('testqueue1');
SELECT pgq.drop_queue('testqueue1');
