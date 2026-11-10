-- https://github.com/Florents-Tselai/pgJQ
CREATE EXTENSION pgjq;

SELECT plan(2);
SELECT is(
    jq('[{"bar": "baz", "balance": 7.77, "active": false}]'::jsonb, '.[0].bar'),
    '"baz"'::jsonb,
    'jq programs select from jsonb'
);
SELECT is(jq('[1, 2, 3]'::jsonb, 'map(. * 2)'), '[2, 4, 6]'::jsonb, 'and transform it');
SELECT * FROM finish(TRUE);
