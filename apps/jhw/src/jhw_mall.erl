-module(jhw_mall).

-include("jhw.hrl").



-export([init/2, handle/1]).
-export([mallInfo/0, supplier/0]).

init(Req0, Opts) ->
	NewReq = jhw_callback:handle(?MODULE, Opts, Req0),
	{ok, NewReq, Opts}.





handle(_Map) ->
	MallInfo = mallInfo(),
	Supplier = supplier(),
	{ok, jsx:encode([
		{<<"status">>, <<"ok">>},
		{<<"mall">>, MallInfo},
		{<<"supplier">>, Supplier}
	])}.



mallInfo() ->
	Fun = fun(#mall{id=Id, name=Name}, List) ->
		[[{<<"id">>, Id}, {<<"name">>, Name}]|List]
	end,
	ets:foldl(Fun, [], mall).



supplier() ->
	Fun = fun(#supplier{id=Id, name=Name}, List) ->
		[[{<<"id">>, Id}, {<<"name">>, Name}]|List]
	end,
	ets:foldl(Fun, [], supplier).



