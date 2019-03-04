-module(jhw_login).

-include("jhw.hrl").

-export([init/2]).

init(Req0, Opts) ->
	{ok, BodyCipher, Req} = cowboy_req:read_body(Req0),
	Body = jhw_auth:decode(BodyCipher),
	
	UUID = cowboy_req:header(<<"uuid">>, Req0),
	PostList = jsx:decode(Body),
	Phone = proplists:get_value(<<"phone">>, PostList),
	Password = proplists:get_value(<<"pwd">>, PostList),

	{RespHeader, RespBody} = handle(UUID, Phone, Password),
	NewReq = jhw_auth:resp(Req, RespHeader, RespBody),
	{ok, NewReq, Opts}.



handle(UUID, Phone, PwdMd5) ->
	case check(UUID, Phone, PwdMd5) of
		{ok, RespHeader, RespBody} ->
			{RespHeader, RespBody};
		{error, ErrorCode} ->
			RespBody = jsx:encode([
				{<<"status">>, <<"error">>},
				{<<"data">>, [<<"code">>, ErrorCode]}
			]),
			{#{}, RespBody}
	end.



check(UUID, Phone, PwdMd5) ->
	case check_phone(Phone) of
		{ok, Uid, Name, Pwd} ->
			case check_pwd(Pwd, PwdMd5, UUID) of
				{ok, Session, Expire} ->
					ets:insert(user, #user{id = Uid, phone = Phone, name = Name, secret = Session, expire = Expire}),
					RespBody = user(Uid, Name),
					RespHeader = #{<<"jhw">> => Session, <<"expire">> => integer_to_binary(Expire)},
					{ok, RespHeader, RespBody};
				ErrorPwd ->
					ErrorPwd
			end;
		ErrorPhone ->
			ErrorPhone
	end.



check_phone(Phone) ->
	Sql = io_lib:format("select id, name, pwd from user where phone = '~s' limit 1", [Phone]),
	case jhw_sql:run(Sql) of
		{ok, _, [[Uid, Name, Pwd]]} -> 
			{ok, Uid, Name, Pwd};
		_ ->
			{error, 1001}
	end.


check_pwd(Pwd, PwdMd5, UUID) ->
	case jhw_util:md5(Pwd) of
		PwdMd5 ->
			ExpireTime = jhw_util:curtime() + 3600,
			Str = binary_to_list(UUID) ++ ":" ++ binary_to_list(PwdMd5) ++ "-" ++ integer_to_list(ExpireTime),
			Session = jhw_util:md5(Str),
			{ok, Session, ExpireTime};
		_ ->
			{error, 1002}
	end.


user(Uid, Name) ->
	MallInfo = jhw_mall:mallInfo(),
	Supplier = jhw_mall:supplier(),
	jsx:encode([
		{<<"status">>, <<"ok">>},
		{<<"userInfo">>, [
			{<<"id">>, Uid},
			{<<"name">>, Name}
		]},
		{<<"mall">>, MallInfo},
		{<<"supplier">>, Supplier}
	]).







