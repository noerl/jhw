-module(jhw_stock).


-export([init/2]).


init(Req0, Opts) ->
	RespBody = handle(Opts, Req0),
	NewReq = cowboy_req:reply(200, #{
		<<"content-type">> => <<"application/json; charset=utf-8">>
	}, RespBody, Req0),
	{ok, NewReq, Opts}.



handle(CallList, Req) ->
	case resp(CallList, Req) of
		{ok, RespBody} -> RespBody;
		{error, ErrorCode} ->
			jsx:encode([
				{<<"status">>, <<"error">>},
				{<<"code">>, ErrorCode}
			])
	end.


resp(CallList, Req) ->
	case jhw_callback:handle(CallList, Req) of
		ok -> 
			handle(Req);
		Error ->
			Error
	end.


handle(Req) ->
	{ok, Body, _Req} = cowboy_req:read_body(Req),
	PostList = jsx:decode(Body),
	Mid = proplists:get_value(<<"mid">>, PostList),
	Search = proplists:get_value(<<"search">>, PostList),

	Sql = io_lib:format("select * from stock where `mid` = ~s and (`barcode` like '%~s%' or `name` like '%~s%') limit 20", [Mid, Search, Search]),
	case jhw_sql:run(Sql) of
		{ok, FieldList, StockList} -> 
			Stock = [lists:zip(FieldList, Stock) || Stock <- StockList],
			{ok, jsx:encode([{<<"status">>, <<"ok">>},{<<"stock">>, Stock}])};
		_error ->
			{error, 1005}
	end.









