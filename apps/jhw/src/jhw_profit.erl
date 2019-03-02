-module(jhw_profit).


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
	StartTime = proplists:get_value(<<"startTime">>, PostList),
	EndTime = proplists:get_value(<<"endTime">>, PostList),

	SqlStr = 
		case Mid of
			0 -> 
				io_lib:format(
					"select `code`,
							`name`,
							`count`,
							`profit`
						from sale
						where `time` >= '~s'
						and `time` <= '~s'", 
				[StartTime, EndTime]);
			_ ->
				io_lib:format(
					"select `code`,
							`name`,
							`count`,
							`profit`
						from 'sale'
						where `mid` = '~p'
						and `time` >= '~s'
						and `time` <= '~s'",
				[Mid, StartTime, EndTime])
		end,
	resp(SqlStr).



resp(SqlStr) ->
	case jhw_sql:run(SqlStr) of
		{ok, _, GoodsList} -> 
			Total = lists:sum([Profit || [_Code, _Name, _Count, Profit] <- GoodsList]),
			ProfitList = [[{<<"code">>, Code}, {<<"name">>, Name}, {<<"count">>, Count}, {<<"profit">>, Profit}] || [Code, Name, Count, Profit] <- GoodsList],
			{ok, jsx:encode([{<<"status">>, <<"ok">>}, {<<"profit">>, [{<<"total">>, Total}, {<<"detail">>, ProfitList}]}])};
		_error ->
			{error, 1005}
	end.








