-module(jhw_purchase).


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
	Sid = proplists:get_value(<<"sid">>, PostList),
	StartTime = proplists:get_value(<<"startTime">>, PostList) div 1000,
	EndTime = proplists:get_value(<<"endTime">>, PostList) div 1000,

	SqlStr = append(Mid, Sid, StartTime, EndTime),
	resp(SqlStr).



resp(SqlStr) ->
	case jhw_sql:run(SqlStr) of
		{ok, _FieldList, []} -> 
			{ok, jsx:encode([{<<"status">>, <<"ok">>}, {<<"purchase">>, []}])};
		{ok, FieldList, PurchaseList} -> 
			Purchase = [lists:zip(FieldList, PurchaseInfo) || PurchaseInfo <- PurchaseList],
			{ok, jsx:encode([{<<"status">>, <<"ok">>}, {<<"purchase">>, Purchase}])};
		_error ->
			{error, 1005}
	end.

append(Mid, Sid, StartTime, EndTime) ->
	SqlStr = 
		io_lib:format(
			"select *
				from buy
				where `time` >= '~p'
				and `time` <= '~p'",
		[StartTime, EndTime]),		
	append([{<<"mid">>, Mid}, {<<"sid">>, Sid}], SqlStr).


append([{_Key, 0}|List], SqlStr) ->
	append(List, SqlStr);
append([{Key, Value}|List], SqlStr) ->
	SqlStr1 = io_lib:format("~s and `~s` = '~p'", [SqlStr,Key,Value]),
	append(List, SqlStr1);
append([], SqlStr) -> SqlStr.





