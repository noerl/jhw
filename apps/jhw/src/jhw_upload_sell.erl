-module(jhw_upload_sell).

-define(FILE_HEAD, <<"店内码,名称,数量,售价"/utf8>>).
-define(FILE_HEAD_LEN, 240).


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
		ok -> create(FileData, Mid);
		Error -> 
			jsx:encode([
				{<<"status">>, <<"error">>},
				Error
			])
	end.


create(<<Head:?FILE_HEAD_LEN, Body/binary>>, Mid) ->
	case <<Head:?FILE_HEAD_LEN>> == ?FILE_HEAD of
		true -> 
			create_sql(Body, Mid);
		false ->
			Msg = unicode:characters_to_binary(io_lib:format("标准格式：~ts, 上传格式：~ts", [?FILE_HEAD, <<Head:?FILE_HEAD_LEN>>])),
			jsx:encode([
				{<<"status">>, <<"error">>},
				{<<"errorMsg">>, Msg}
			])
	end.
	


create_sql(Bin, Mid) ->
	BodyList = binary:split(Bin, <<"\r\n">>, [global]),
	CurMon = jhw_util:cur_mon(),
	create_sql(BodyList, [], [], Mid, CurMon).


create_sql([<<>>|List], SqlList, ErrorList, Mid, CurMon) ->
	create_sql(List, SqlList, ErrorList, Mid, CurMon);
create_sql([Body|List], SqlList, ErrorList, Mid, CurMon) ->
	case binary:split(Body, <<",">>, [global]) of
		[Code, Name, CountBin, SellPriceBin] ->
			Count = jhw_util:binary_to_num(CountBin),
			SellPrice = jhw_util:binary_to_num(SellPriceBin),

			SelectSql = io_lib:format("select `count`, `buyPrice` from stock where `mid` = '~s' and `code` = '~s'", [Mid, Code]),
			{Profit, SqlList1} = 
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
						{ProfitTmp, [UpdateStock|SqlList]};
					_ ->
						{SellPrice, SqlList}
				end,
			Sql = io_lib:format("replace into sale(`mid`,`code`,`mon`,`name`,`count`,`price`, `profit`) values ('~s','~s','~p','~s','~p','~p','~p');", [Mid, Code, CurMon, Name, Count, SellPrice, Profit]),
			create_sql(List, [Sql|SqlList1], ErrorList, Mid, CurMon);
		_ ->
			create_sql(List, SqlList, [Body|ErrorList], Mid, CurMon)
	end;
create_sql([], SqlList, ErrorList, _Mid, _CurMon) ->
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







