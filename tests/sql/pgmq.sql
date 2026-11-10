-- https://github.com/pgmq/pgmq
CREATE EXTENSION pgmq;

SELECT pgmq.create('my_queue');
SELECT * FROM pgmq.send(queue_name => 'my_queue', msg => '{"foo": "bar1"}');
SELECT * FROM pgmq.send(queue_name => 'my_queue', msg => '{"foo": "bar2"}', delay => 1);
SELECT * FROM pgmq.read(queue_name => 'my_queue', vt => 30, qty => 2);
SELECT * FROM pgmq.pop('my_queue');
SELECT pgmq.send_batch(
	queue_name => 'my_queue',
	msgs => ARRAY['{"foo": "bar3"}', '{"foo": "bar4"}', '{"foo": "bar5"}']::jsonb[]
);
SELECT pgmq.archive(queue_name => 'my_queue', msg_ids => ARRAY[3, 4, 5]);

SELECT plan(1);
SELECT is((SELECT count(*) FROM pgmq.a_my_queue), 3::bigint, 'messages are archived');
SELECT * FROM finish(TRUE);

SELECT pgmq.drop_queue('my_queue');
