-module(jhw_upload_buy).

%% 商品名称，条形码，商品店内码，正常售价
-define(EXCEL_NAME, 		<<"商品名称"/utf8>>).
-define(EXCEL_BARCODE, 		<<"条形码"/utf8>>).
-define(EXCEL_CODE, 		<<"商品店内码"/utf8>>).
-define(EXCEL_PRICE, 		<<"正常售价"/utf8>>).



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


	io:format("Mid:~p, Key:~p~n", [Phone, Key]),
	% {file, <<"inputfile">>, Filename, ContentType}
	% 	= cow_multipart:form_data(Headers),
	RespBody = check(Phone, Key, FileData, Mid),
		
	NewReq = cowboy_req:reply(200, #{
		<<"content-type">> => <<"application/json; charset=utf-8">>
	}, RespBody, Req9),
	{ok, NewReq, Opts}.


check(Phone, Key, FileData, Mid) ->
	case jhw_auth:check(Phone, Key) of
		ok ->
			create_sql(FileData, Mid);
		Error -> 
			jsx:encode([
				{<<"status">>, <<"error">>},
				Error
			])
	end.


	

create_sql(Bin, Mid) ->
	[Header|BodyList] = binary:split(Bin, <<"\r\n">>, [global]),
	HeaderList = binary:split(Header, <<",">>, [global]),
	IndexList = lists:seq(1, length(HeaderList)),
	KeyList = lists:zip(HeaderList, IndexList),
	io:format("~p~n", [KeyList]),
	create_sql(BodyList, KeyList, [], [], Mid).




create_sql([<<>>|List], KeyList, SqlList, ErrorList, Mid) ->
	create_sql(List, KeyList, SqlList, ErrorList, Mid);
create_sql([Body|List], KeyList, SqlList, ErrorList, Mid) ->
	ValueList = binary:split(Body, <<",">>, [global]),
	{_, NameIndex} = lists:keyfind(?EXCEL_NAME, 1, KeyList),
	{_, CodeIndex} = lists:keyfind(?EXCEL_CODE, 1, KeyList),
	{_, BarCodeIndex} = lists:keyfind(?EXCEL_BARCODE, 1, KeyList),
	{_, PriceIndex} = lists:keyfind(?EXCEL_PRICE, 1, KeyList),

	Name = lists:nth(NameIndex, ValueList),
	Code = lists:nth(CodeIndex, ValueList),
	BarCode = lists:nth(BarCodeIndex, ValueList),
	Price = lists:nth(PriceIndex, ValueList),

	SelectSql = io_lib:format("select `sellPrice` from stock where `mid` = '~s' and `code` = '~s'", [Mid, Code]),
	SqlList1 = 
		case jhw_sql:run(SelectSql) of
			{ok, _, [[OldPrice]]} -> 
				case jhw_util:binary_to_num(Price) == OldPrice of
					true -> ok;
					false -> io:format("OldPrice:~p, Price:~s", [OldPrice, Price])
				end,
				SqlList;
			_ ->
				Sql = io_lib:format("insert into stock(`mid`,`code`,`barcode`,`name`,`sellPrice`) values ('~s','~s','~s','~s','~s');", [Mid, Code, BarCode, Name, Price]),
				[Sql|SqlList]
		end,
	create_sql(List, KeyList, SqlList1, ErrorList, Mid);
create_sql([], _KeyList, SqlList, ErrorList, _Mid) ->
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

			


