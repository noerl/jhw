-module(jhw_upload_sell).

%% 商品名称，条形码，商品店内码，正常售价
-define(EXCEL_NAME, 		<<"商品名称/utf8">>).
-define(EXCEL_CODE, 		<<"商品店内码/utf8">>).
-define(EXCEL_COUNT, 		<<"数量/utf8">>).
-define(EXCEL_PRICE, 		<<"售价/utf8">>).


-export([init/2]).


init(Req, Opts) ->
	{ok, _FileHeader, Req2} = cowboy_req:read_part(Req),
	{ok, FileData, Req3} = cowboy_req:read_part_body(Req2),

	{ok, _MallHeader, Req4} = cowboy_req:read_part(Req3),
	{ok, Mid, Req5} = cowboy_req:read_part_body(Req4),

	{ok, _PhoneHeader, Req6} = cowboy_req:read_part(Req5),
	{ok, Phone, Req7} = cowboy_req:read_part_body(Req6),

	{ok, _KeyHeader, Req8} = cowboy_req:read_part(Req7),
	{ok, Key, Req9} = cowboy_req:read_part_body(Req8),

	io:format("Mid:~p, Key:~p~n", [Mid, Key]),
	% {file, <<"inputfile">>, Filename, ContentType}
	% 	= cow_multipart:form_data(Headers),
	RespBody = check(Phone, Key, FileData, Mid),
	NewReq = cowboy_req:reply(200, #{
		<<"content-type">> => <<"application/json; charset=utf-8">>
	}, RespBody, Req9),
	{ok, NewReq, Opts}.


check(Phone, Key, FileData, Mid) ->
	case jhw_auth:check(Phone, Key) of
		ok -> create_sql(FileData, Mid);
		Error -> 
			jsx:encode([
				{<<"status">>, <<"error">>},
				Error
			])
	end.





create_sql(Bin, Mid) ->
	[Header|BodyList] = binary:split(Bin, <<"\r\n">>, [global]),
	CurTime = jhw_util:curtime(),

	IndexList = lists:seq(1, length(Header)),
	KeyList = lists:zip(Header, IndexList),
	create_sql(BodyList, KeyList, [], [], Mid, CurTime).


create_sql([<<>>|List], KeyList, SqlList, ErrorList, Mid, CurTime) ->
	create_sql(List, KeyList, SqlList, ErrorList, Mid, CurTime);
create_sql([Body|List], KeyList, SqlList, ErrorList, Mid, CurTime) ->
	ValueList = binary:split(Body, <<",">>, [global]),
	{_, NameIndex} = lists:keyfind(?EXCEL_NAME, 1, KeyList),
	{_, CodeIndex} = lists:keyfind(?EXCEL_CODE, 1, KeyList),
	{_, CountIndex} = lists:keyfind(?EXCEL_COUNT, 1, KeyList),
	{_, PriceIndex} = lists:keyfind(?EXCEL_PRICE, 1, KeyList),

	Name = lists:nth(NameIndex, ValueList),
	Code = lists:nth(CodeIndex, ValueList),
	CountBin = lists:nth(CountIndex, ValueList),
	PriceBin = lists:nth(PriceIndex, ValueList),
	Count = jhw_util:binary_to_num(CountBin),
	SellPrice = jhw_util:binary_to_num(PriceBin),

	SelectSql = io_lib:format("select `count`, `buyPrice` from stock where `mid` = '~s' and `code` = '~s'", [Mid, Code]),
	{Profit, SqlList1, Price} = 
		case jhw_sql:run(SelectSql) of
			{ok, _, [[OldCount, BuyPrice]]} -> 
				io:format("info:~p~n", [[OldCount, BuyPrice, SellPrice, Count]]),
				ProfitTmp = SellPrice - Count * BuyPrice,
				LastCount = 
					case OldCount - Count >= 0 of
						true -> OldCount - Count;
						false -> 
							io:format("count:~p, oldCount:~p~n", [Count, OldCount]),
							0
					end,
				UpdateStock = io_lib:format("update stock set `count` = '~p' where `mid` = '~s' and `code` = '~s'", [LastCount, Mid, Code]),
				{ProfitTmp, [UpdateStock|SqlList], BuyPrice};
			_ ->
				{SellPrice, SqlList, 0}
		end,
	Sql = io_lib:format("replace into sale(`mid`,`code`,`time`,`name`,`count`,`sale`, `buyPrice` `profit`) values ('~s','~s','~p','~s','~p','~p','~p','~p');", [Mid, Code, CurTime, Name, Count, SellPrice, Price, Profit]),
	create_sql(List, KeyList, [Sql|SqlList1], ErrorList, Mid, CurTime);
create_sql([], _KeyList, SqlList, ErrorList, _Mid, _CurTime) ->
	case jhw_sql:transaction(SqlList) of
		{atomic, SuccList} ->
			jsx:encode([
				{<<"status">>, <<"ok">>},
				{<<"succLen">>, length(SuccList)},
				{<<"failList">>, ErrorList}
			]);
		_Error ->
			io:format("error:~p~n", [_Error]),
			jsx:encode([
				{<<"status">>, <<"error">>}
			])
	end.







