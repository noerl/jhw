%%%-------------------------------------------------------------------
%% @doc jhw top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(jhw_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%====================================================================
%% API functions
%%====================================================================

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%% Child :: #{id => Id, start => {M, F, A}}
%% Optional keys are restart, shutdown, type, modules.
%% Before OTP 18 tuples must be used to specify a child. e.g.
%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->
	PoolArgs = [{name, {local, sql}}, {worker_module, mysql}, {size, 10}, {max_overflow, 20}],
	WorkerArgs = [{user, "root"}, {password, "bin123"}, {database, "jhw"},{host, "127.0.0.1"}],
	Mysql = poolboy:child_spec(sql, PoolArgs, WorkerArgs),
	io:format("Mysql:~p~n", [Mysql]),
    {ok, {{one_for_all, 0, 1}, [Mysql]}}.

%%====================================================================
%% Internal functions
%%====================================================================
