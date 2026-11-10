-- preload: plugin_debugger
-- https://github.com/EnterpriseDB/pldebugger
CREATE EXTENSION pldbgapi;

SELECT * FROM pldbg_get_proxy_info();
SELECT pldbg_create_listener();
