-module(jhw_mall).

-include("jhw.hrl").

-export([init/2, mallInfo/0, supplier/0]).

init(Req0, Opts) ->
	io:format("Req0:~p~n", [Req0]),
	RespBody = handle(Opts, Req0),
	NewReq = cowboy_req:reply(200, #{
		<<"content-type">> => <<"application/json; charset=utf-8">>
	}, RespBody, Req0),
	{ok, NewReq, Opts}.




handle(Opts, Req) ->
	case jhw_callback:handle(Opts, Req) of
		ok -> 
			MallInfo = mallInfo(),
			Supplier = supplier(),
			jsx:encode([
				{<<"status">>, <<"ok">>},
				{<<"mall">>, MallInfo},
				{<<"supplier">>, Supplier}
			]);
		{error, ErrorCode} ->
			jsx:encode([
				{<<"status">>, <<"error">>},
				{<<"data">>, [<<"code">>, ErrorCode]}
			])
	end.



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



