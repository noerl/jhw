-module(jhw_stock).


-export([init/2, handle/1]).

init(Req0, Opts) ->
	NewReq = jhw_callback:handle(?MODULE, Opts, Req0),
	{ok, NewReq, Opts}.


handle(#{body := Body}) ->
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









