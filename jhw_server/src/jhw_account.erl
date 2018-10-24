-module(jhw_account).

-include("jhw.hrl").

-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

init(_Transport, Req, []) ->
	{ok, Req, undefined}.

handle(Req, State) ->
	{ok, Body, _} = cowboy_req:body(Req),
	DataList = jsx:decode(Body),
	io:format("DataList:~p~n", [DataList]),
	{ok, NewReq} = resp(Req, DataList),
	{ok, NewReq, State}.




terminate(_Reason, _Req, _State) ->
	ok.


resp(Req, DataList) ->
	Body = 
		case check(Req, DataList) of
			{ok, ResponseData} ->
				jsx:encode([{<<"state">>, <<"ok">>},{<<"data">>, ResponseData}]);
			{error, Error} ->
				jsx:encode([{<<"state">>, <<"error">>},{<<"type">>, Error}])
		end,
	cowboy_req:reply(200, [{"content-type","application/json"},{<<"Access-Control-Allow-Origin">>,<<"*">>}], Body, Req).


check(Req, DataList) ->
	case jhw_auth:auth_ex(Req) of
		{ok, Account} ->
			Type = proplists:get_value(<<"type">>, DataList),
			Data = proplists:get_value(<<"data">>, DataList),
			handle_account(Type, Data, Account);
		Error ->
			Error
	end.



handle_account(1, DataList, _) ->
	add(DataList);
handle_account(2, DataList, _) ->
	del(DataList);
handle_account(3, _, _) ->
	account_info().


add(DataList) ->
	User = proplists:get_value(<<"user">>, DataList),
	Pwd = proplists:get_value(<<"pwd">>, DataList),
	Auth = proplists:get_value(<<"auth">>, DataList, 0),
	Shop = proplists:get_value(<<"shop">>, DataList),
	add(User, Pwd, Auth, Shop).


add(User, Pwd, Auth, Shop) ->
	Account = #account{user = User, pwd = Pwd, auth = Auth, shop = Shop},
	ets:insert(account, Account),
	{ok, []}.



del(DataList) ->
	User = proplists:get_value(<<"user">>, DataList),
	ets:delete(account, User),
	{ok, []}.


account_info() ->
	Fun = fun(#account{user = User, pwd = Pwd}, List) ->
			[[{<<"user">>, User}, {<<"pwd">>, Pwd}]|List]
		end,
	Data = ets:foldl(Fun, [], account),
	{ok, Data}.



	




