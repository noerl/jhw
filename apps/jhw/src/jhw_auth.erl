-module(jhw_auth).

-include("jhw.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

-export([
	handle/1,
	check/2
]).






handle(Req) ->
	<<"JHW ", Auth/binary>> = cowboy_req:header(<<"authorization">>, Req),
	[UidBin, Secret] = binary:split(Auth, <<":">>),
	handle(binary_to_integer(UidBin), Secret).



handle(Uid, Secret) ->
	case ets:lookup(user, Uid) of
		[#user{secret = Secret, expire = Expire}] ->
			CurTime = jhw_util:curtime(),
			case Expire >= CurTime of
				true -> 
					put('$uid', Uid),
					ok;
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
