-module(jhw_price).


-export([init/2, handle/1]).

init(Req0, Opts) ->
	NewReq = jhw_callback:handle(?MODULE, Opts, Req0),
	{ok, NewReq, Opts}.


handle(#{body := Body}) ->
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








