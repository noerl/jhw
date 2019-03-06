-module(jhw_search).


-export([init/2, handle/1]).

init(Req0, Opts) ->
	NewReq = jhw_callback:handle(?MODULE, Opts, Req0),
	{ok, NewReq, Opts}.


handle(#{body := Body}) ->
	PostList = jsx:decode(Body),
	Mid = proplists:get_value(<<"mid">>, PostList),
	Sid = proplists:get_value(<<"sid">>, PostList),
	Msg = proplists:get_value(<<"msg">>, PostList),

	SqlStr = append([{<<"mid">>, Mid}, {<<"sid">>, Sid}]),
	
	SqlStr1 = io_lib:format("select * from stock where~s (`code` like '%~s%' or `barcode` like '%~s%' or `name` like '%~s%') limit 50", [SqlStr, Msg, Msg, Msg]),

	case jhw_sql:run(SqlStr1) of
		{ok, FieldList, StockList} -> 
			Stock = [lists:zip(FieldList, Stock) || Stock <- StockList],
			{ok, jsx:encode([{<<"status">>, <<"ok">>},{<<"stock">>, Stock}])};
		_error ->
			{error, 1005}
	end.



append(List) ->
	append(List, "").


append([{<<"mid">>, 0} | List], SqlStr) ->
	append(List, SqlStr);
append([{<<"sid">>, 0} | List], SqlStr) ->
	append(List, SqlStr);
append([{Key, Value}|List], SqlStr) ->
	SqlStr1 = io_lib:format("~s `~s` = '~p' and", [SqlStr, Key, Value]),
	append(List, SqlStr1);
append([], SqlStr) -> SqlStr.
	
	
	 









