-module(jhw_upload_buy).

-define(FILE_HEAD, <<"店内码,条码,名称,售价"/utf8>>).
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
	create_sql(BodyList, [], [], Mid).


create_sql([<<>>|List], SqlList, ErrorList, Mid) ->
	create_sql(List, SqlList, ErrorList, Mid);
create_sql([Body|List], SqlList, ErrorList, Mid) ->
	case binary:split(Body, <<",">>, [global]) of
		[Code, BarCode, Name, Price] ->
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
			create_sql(List, SqlList1, ErrorList, Mid);
		_I ->
			io:format("~p~n", [_I]),
			create_sql(List, SqlList, [Body|ErrorList], Mid)
	end;
create_sql([], SqlList, ErrorList, _Mid) ->
	io:format("SqlList:~p~n", [SqlList]),
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

			


