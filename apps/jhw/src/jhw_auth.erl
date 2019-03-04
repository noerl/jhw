-module(jhw_auth).

-include("jhw.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

-define(AES_KEY, <<"1234567812345key">>).
-define(AES_IV,  <<"iv12345678123456">>).

-export([
	handle/2,
	check/2,
	encode/1,
	decode/1,
	resp/2,
	resp/3
]).





handle(Req, Map) ->
	<<"JHW ", Auth/binary>> = cowboy_req:header(<<"authorization">>, Req),
	[UidBin, Secret] = binary:split(Auth, <<":">>),
	{ok, BodyCipher, _Req} = cowboy_req:read_body(Req),
	Body = jhw_auth:decode(BodyCipher),
	handle(binary_to_integer(UidBin), Secret, Map#{body => Body}).



handle(Uid, Secret, Map) ->
	case ets:lookup(user, Uid) of
		[#user{secret = Secret, expire = Expire}] ->
			CurTime = jhw_util:curtime(),
			case Expire >= CurTime of
				true -> 
					{ok, Map#{id => Uid}};
				false -> 
					{error, 1004}
			end;
		_ ->
			{error, 1003}
	end.


check(Phone, Code) ->
	Ms = ets:fun2ms(fun(User) when User#user.phone =:= Phone andalso User#user.captcha =:= Code -> User end),
	case ets:select(user, Ms) of
		[] -> {error, 1101};
		_User -> ok
	end.


resp(Req, Body) ->
	resp(Req, #{}, Body).

resp(Req, Header, Body) ->
	EncryptBody = encode(Body),
	cowboy_req:reply(200, Header#{
		<<"content-type">> => <<"text/plain; charset=utf-8">>
	}, EncryptBody, Req).



encode(Bin) ->
	Len = erlang:size(Bin),
	Value = 16 - (Len rem 16),
	PadBin = binary:copy(<<Value>>, Value),
	EncodeB = crypto:block_encrypt(aes_cbc128, ?AES_KEY, ?AES_IV, <<Bin/binary, PadBin/binary>>),
	base64:encode(EncodeB).


decode(Bin) ->
	Bin1 = base64:decode(Bin),
	case erlang:size(Bin1) rem 16 of
		0 -> 
			Bin2 = crypto:block_decrypt(aes_cbc128, ?AES_KEY, ?AES_IV, Bin1),
			binary:part(Bin2, {0, byte_size(Bin2) - binary:last(Bin2)});
		_ -> 
			{error, 1102}
	end.
		





