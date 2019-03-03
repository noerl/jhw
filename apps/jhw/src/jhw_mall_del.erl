-module(jhw_mall_del).

-include("jhw.hrl").

-export([init/2]).

init(Req0, Opts) ->
	RespBody = handle(Opts, Req0),
	NewReq = cowboy_req:reply(200, #{
		<<"content-type">> => <<"application/json; charset=utf-8">>
	}, RespBody, Req0),
	{ok, NewReq, Opts}.




handle(Opts, Req) ->
	case jhw_callback:handle(Opts, Req) of
		ok -> 
			handle(Req);
		{error, ErrorCode} ->
			jsx:encode([
				{<<"status">>, <<"error">>},
				{<<"data">>, [<<"code">>, ErrorCode]}
			])
	end.


handle(Req) ->
    {ok, Body, _Req} = cowboy_req:read_body(Req),
	PostList = jsx:decode(Body),
	Id = proplists:get_value(<<"id">>, PostList),
    Sql = io_lib:format("delete from mall where `id` = '~p'", [Id]),
    case jhw_sql:run(Sql) of
        ok ->
            ets:delete(mall, Id),
			jhw_html:mall(),
            jsx:encode([{<<"status">>, <<"ok">>},{<<"mallDel">>, [{<<"id">>, Id}]}]);
        _ ->
            {error, 1005}
    end.





