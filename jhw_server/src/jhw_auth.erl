-module(jhw_auth).

-include("jhw.hrl").

-export([
	auth/1,
	auth_ex/1,
	auth/2,
	auth/3
]).


auth(Req) ->
	{User, Req1} = cowboy_req:cookie(<<"user">>, Req),
	{Id, _Req2} = cowboy_req:cookie(<<"aid">>, Req1),
	auth(User, Id).

auth_ex(Req) ->
	{User, Req1} = cowboy_req:cookie(<<"user">>, Req),
	{Id, _Req2} = cowboy_req:cookie(<<"aid">>, Req1),
	auth(User, Id, 1).


auth(User, Id) ->
	case ets:lookup(account, User) of
		[#account{id = Id} = Account] ->
			{ok, Account};
		_ ->
			{error, 1}		%% 重新登录
	end.


auth(User, Id, Auth) ->
	case ets:lookup(account, User) of
		[#account{id = Id, auth = Auth} = Account] ->
			{ok, Account};
		_ ->
			{error, 1}		%% 重新登录
	end.