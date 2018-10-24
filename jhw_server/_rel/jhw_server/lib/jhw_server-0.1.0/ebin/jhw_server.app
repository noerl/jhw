{application, 'jhw_server', [
	{description, "New project"},
	{vsn, "0.1.0"},
	{modules, ['jhw_account','jhw_auth','jhw_item','jhw_login','jhw_server_app','jhw_server_sup']},
	{registered, [jhw_server_sup]},
	{applications, [kernel,stdlib,mnesia,jsx,cowboy]},
	{mod, {jhw_server_app, []}},
	{env, []}
]}.