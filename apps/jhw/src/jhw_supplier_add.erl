-module(jhw_supplier_add).

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
    Sql = io_lib:format("insert into supplier(`name`) values ('~s')", [Name]),
    case jhw_sql:insert(Sql) of
        {ok, Id} ->
            ets:insert(supplier, #supplier{id = Id, name = Name}),
            jsx:encode([{<<"status">>, <<"ok">>},{<<"supplierAdd">>, [{<<"id">>, Id}, {<<"name">>, Name}]}]);
        _ ->
            {error, 1005}
    end.





