-- preload: plugin_debugger
-- https://github.com/EnterpriseDB/pldebugger
CREATE EXTENSION pldbgapi;

SELECT plan(2);
-- The proxy reports the version it was built against, which may be an older minor release.
SELECT is(
	(SELECT serverversionnum / 10000 FROM pldbg_get_proxy_info()),
	current_setting('server_version_num')::integer / 10000,
	'the debugger proxy reports the server major'
);
SELECT ok(pldbg_create_listener() > 0, 'debugging sessions are opened');
SELECT * FROM finish(TRUE);
