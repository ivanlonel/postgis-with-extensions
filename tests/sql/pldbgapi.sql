-- preload: plugin_debugger
-- https://github.com/EnterpriseDB/pldebugger
CREATE EXTENSION pldbgapi;

SELECT plan(2);
SELECT is(
	(SELECT serverversionnum FROM pldbg_get_proxy_info()),
	current_setting('server_version_num')::integer,
	'the debugger proxy reports the server'
);
SELECT ok(pldbg_create_listener() > 0, 'debugging sessions are opened');
SELECT * FROM finish(TRUE);
