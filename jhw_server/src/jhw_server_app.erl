-module(jhw_server_app).
-behaviour(application).

-include("jhw.hrl").

-export([start/2]).
-export([stop/1]).

start(normal, []) ->
	init_account(),
	Dispatch = cowboy_router:compile([
		{'_', [
			{"/", cowboy_static, {priv_file, jhw_server, "index.html"}},
			{"/account", jhw_account, []},
			{"/login", jhw_login, []},
			{"/item", jhw_item, []},
			{"/[...]", cowboy_static, {priv_dir, jhw_server, "",
				[{mimetypes, cow_mimetypes, all}]}}
		]}
	]),
	{ok, _} = cowboy:start_http(http, 100, [{port, 9231}], [
		{env, [{dispatch, Dispatch}]}
	]),
	jhw_server_sup:start_link().

stop(_State) ->
	ok.



init_account() ->
	ets:new(account, [named_table, public, {keypos, #account.user}]),
	ets:new(item, [named_table, public, {keypos, #item.id}]),
	ets:new(id, [named_table, public]),
	ets:insert(account, #account{user = <<"18682410521">>, pwd = <<"20181010">>, auth = 1}).








