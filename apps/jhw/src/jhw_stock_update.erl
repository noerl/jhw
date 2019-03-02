-module(jhw_stock_update).


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
	Code = proplists:get_value(<<"code">>, PostList),
	BuyPrice = proplists:get_value(<<"buyPrice">>, PostList),
	Count = proplists:get_value(<<"count">>, PostList),
	Sid = proplists:get_value(<<"sid">>, PostList),

	SelectSql = io_lib:format("select `name`, `barcode`, `buyPrice`, `count` from stock where `mid` = '~p' and `code` = '~s' limit 1", [Mid, Code]),
	case jhw_sql:run(SelectSql) of
		{ok, _FieldList, [[Name, Barcode, OldPrice, OldCount]]} -> 
			NewCount = OldCount + Count,

			NewPriceCent = erlang:floor((BuyPrice * Count + OldPrice*OldCount) * 100) div NewCount,
			NewPrice = 
				case NewPriceCent rem 10 of
					0 -> (NewPriceCent div 10) / 10;
					_ -> ((NewPriceCent div 10) + 1) / 10
				end,

			StockSql = io_lib:format("update stock set `buyPrice` = '~p', `count` = '~p', `sid` = '~p' where `mid` = '~p' and `code` = '~s'", [NewPrice, NewCount, Sid, Mid, Code]),

			Time = jhw_util:curtime(),
			BuySql = io_lib:format("insert buy (`mid`, `sid`, `time`, `name`, `code`, `barcode`, `price`, `count`) values ('~p', '~p', '~p', '~s', '~s', '~s', '~p', '~p')", [Mid, Sid, Time, Name, Code, Barcode, BuyPrice, Count]),

			case jhw_sql:transaction([StockSql, BuySql]) of
				{atomic, SuccList} when length(SuccList) == 2 ->
					{ok, jsx:encode([{<<"status">>, <<"ok">>},{<<"stock">>, [{<<"price">>, NewPrice}, {<<"count">>, NewCount}]}])};
				_Error ->
					io:format("error:~p~n", [_Error]),
					jsx:encode([
						{<<"status">>, <<"error">>}
					])
			end;
		_error ->
			{error, 1005}
	end.










