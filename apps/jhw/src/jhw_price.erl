-module(jhw_price).


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
	Code = proplists:get_value(<<"code">>, PostList),

	Sql = io_lib:format("select `price`, `sid`, `time` from buy where `code` = '~s' order by time desc limit 3", [Code]),
	case jhw_sql:run(Sql) of
		{ok, _, PriceList} -> 
			PriceLogList = [[{<<"price">>, Price}, {<<"sid">>, Sid}, {<<"time">>, Time}] || [Price, Sid, Time] <- PriceList],
			{ok, jsx:encode([{<<"status">>, <<"ok">>}, {<<"priceLog">>, PriceLogList}])};
		_error ->
			{error, 1005}
	end.








