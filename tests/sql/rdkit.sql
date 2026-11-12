-- image: extended
-- https://github.com/rdkit/rdkit (its PostgreSQL cartridge)
CREATE EXTENSION rdkit;

CREATE TABLE molecules (id integer PRIMARY KEY, m mol NOT NULL);
INSERT INTO molecules VALUES
(1, 'c1ccccc1O'),  -- phenol
(2, 'CCO'),        -- ethanol
(3, 'c1ccccc1N'),  -- aniline
(4, 'CC(=O)O');    -- acetic acid
CREATE INDEX molecules_m_idx ON molecules USING gist (m);
ANALYZE molecules;
SELECT set_config('enable_seqscan', 'off', FALSE);

SELECT plan(5);
SELECT is(mol_formula('c1ccccc1O'::mol)::text, 'C6H6O', 'molecular formulas are computed');
SELECT is(round(mol_amw('CCO'::mol)::numeric, 2), 46.07, 'molecular weights are computed');
SELECT results_eq(
    $$SELECT id FROM molecules WHERE m @> 'c1ccccc1'::mol ORDER BY id$$,
    ARRAY[1, 3],
    'substructure searches find the benzene rings'
);
SELECT matches(
    plan_of($$SELECT id FROM molecules WHERE m @> 'c1ccccc1'::mol$$),
    'molecules_m_idx',
    'substructure searches use the GiST index'
);
SELECT is(
    tanimoto_sml(morganbv_fp('c1ccccc1O'::mol), morganbv_fp('c1ccccc1O'::mol)),
    1::float8,
    'a molecule is identical to itself'
);
SELECT * FROM finish(TRUE);
