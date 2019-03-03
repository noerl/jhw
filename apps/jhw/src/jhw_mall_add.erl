-module(jhw_mall_add).

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
	Name = proplists:get_value(<<"name">>, PostList),
    Sql = io_lib:format("insert into mall(`name`) values ('~s')", [Name]),
    case jhw_sql:insert(Sql) of
        {ok, Id} ->
            ets:insert(mall, #mall{id = Id, name = Name}),
			jhw_html:mall(ets:tab2list(mall)),
            jsx:encode([{<<"status">>, <<"ok">>},{<<"mallAdd">>, [{<<"id">>, Id}, {<<"name">>, Name}]}]);
        _ ->
            {error, 1005}
    end.





