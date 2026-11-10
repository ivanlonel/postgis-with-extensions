-- https://github.com/pgmq/pgmq
CREATE EXTENSION pgmq;

SELECT pgmq.create('my_queue');
SELECT * FROM pgmq.send(queue_name => 'my_queue', msg => '{"foo": "bar1"}');
SELECT * FROM pgmq.send(queue_name => 'my_queue', msg => '{"foo": "bar2"}');
CREATE TEMPORARY TABLE first_read AS
SELECT * FROM pgmq.read(queue_name => 'my_queue', vt => 30, qty => 1);
CREATE TEMPORARY TABLE second_read AS
SELECT * FROM pgmq.read(queue_name => 'my_queue', vt => 30, qty => 10);
SELECT pgmq.delete('my_queue', (SELECT msg_id FROM first_read));
SELECT pgmq.send_batch(
    queue_name => 'my_queue',
    msgs => ARRAY['{"foo": "bar3"}', '{"foo": "bar4"}', '{"foo": "bar5"}']::jsonb[]
);
SELECT pgmq.archive(queue_name => 'my_queue', msg_ids => ARRAY[3, 4, 5]);

SELECT plan(5);
SELECT is((SELECT message ->> 'foo' FROM first_read), 'bar1', 'messages are read in order');
SELECT is(
    (SELECT array_agg(message ->> 'foo') FROM second_read),
    ARRAY['bar2'],
    'read messages stay invisible for the visibility timeout'
);
SELECT is((
    SELECT count(*) FROM pgmq.q_my_queue
    WHERE msg_id = 1
), 0::bigint, 'messages are deleted');
SELECT is((SELECT count(*) FROM pgmq.a_my_queue), 3::bigint, 'messages are archived');
SELECT is((SELECT queue_length FROM pgmq.metrics('my_queue')), 1::bigint, 'queues report metrics');
SELECT * FROM finish(TRUE);

SELECT pgmq.drop_queue('my_queue');
