-- https://github.com/cybertec-postgresql/pg_permissions
CREATE EXTENSION pg_permissions;

CREATE ROLE pwe_permissions_reader;
CREATE TABLE ledger (id integer PRIMARY KEY, amount numeric);
GRANT SELECT ON ledger TO pwe_permissions_reader;

-- Declare the permissions the role should have, and compare with reality.
INSERT INTO permission_target (id, role_name, permissions, object_type, schema_name, object_name)
VALUES (1, 'pwe_permissions_reader', '{SELECT,INSERT}', 'TABLE', 'public', 'ledger');

SELECT plan(3);
SELECT ok(
    (
        SELECT granted FROM table_permissions
        WHERE role_name = 'pwe_permissions_reader' AND object_name = 'ledger' AND permission = 'SELECT'
    ),
    'granted permissions are reported'
);
SELECT ok(
    (
        SELECT NOT granted FROM table_permissions
        WHERE role_name = 'pwe_permissions_reader' AND object_name = 'ledger' AND permission = 'INSERT'
    ),
    'missing permissions are reported'
);
SELECT is(
    (
        SELECT count(*) FROM permission_diffs()
        WHERE role_name = 'pwe_permissions_reader' AND missing
    ),
    1::bigint,
    'differences from the target are found'
);
SELECT * FROM finish(TRUE);

DROP TABLE ledger;
DROP ROLE pwe_permissions_reader;
