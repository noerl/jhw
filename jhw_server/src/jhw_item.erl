-module(jhw_item).

-include("jhw.hrl").

-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

init(_Transport, Req, []) ->
	{ok, Req, undefined}.

handle(Req, State) ->
	{ok, Body, _} = cowboy_req:body(Req),
	DataList = jsx:decode(Body),
	Type = proplists:get_value(<<"type">>, DataList),
	Data = proplists:get_value(<<"data">>, DataList),
	{ok, NewReq} = check(Req, Type, Data),
	{ok, NewReq, State}.

	


terminate(_Reason, _Req, _State) ->
	ok.




	
check(Req, Type, Data) ->
	Body = 
		case check_cookie(Req, Type, Data) of
			{ok, ResponseData} ->
				jsx:encode([{<<"state">>, <<"ok">>},{<<"data">>, ResponseData}]);
			{error, Error} ->
				jsx:encode([{<<"state">>, <<"error">>},{<<"type">>, Error}])
		end,
	cowboy_req:reply(200, [{"content-type","application/json"},{<<"Access-Control-Allow-Origin">>,<<"*">>}], Body, Req).



check_cookie(Req, Type, Data) ->
	case jhw_auth:auth(Req) of
		{ok, Account} ->
			item(Type, Data, Account);
		Error ->
			Error
	end.




item(1, Data, Account) ->
	item_insert(Data, Account);
item(2, Data, Account) ->
	item_delete(Data, Account);
item(3, Data, _Account) ->
	item_update(Data);
item(4, _Data, Account) ->
	item_select(Account).


item_insert(Data, Account) ->
	#account{user = User, item_list = OldList} = Account,
	Code = proplists:get_value(<<"code">>, Data),
	Name = proplists:get_value(<<"name">>, Data),
	Count = proplists:get_value(<<"count">>, Data),
	Id = id(User),
	CurSec = curtime(),
	ItemList = [Id | OldList],
	Item = #item{id = Id, code = Code, name = Name, count = Count, time = CurSec},
	ets:insert(item, Item),
	ets:insert(account, Account#account{item_list = ItemList}),
	{ok, [{<<"id">>, Id}]}.

item_delete(Data, Account) ->
	IdList = proplists:get_value(<<"idList">>, Data),
	ItemList = Account#account.item_list -- IdList,
	Fun = fun(ItemId) -> ets:delete(item, ItemId) end,
	lists:foreach(Fun, IdList),
	ets:insert(account, Account#account{item_list = ItemList}),
	{ok, []}.


item_update(Data) ->
	Id = proplists:get_value(<<"id">>, Data),
	Code = proplists:get_value(<<"code">>, Data),
	Name = proplists:get_value(<<"name">>, Data),
	Count = proplists:get_value(<<"count">>, Data),
	CurSec = curtime(),
	case ets:lookup(item, Id) of
		[_] ->  
			Item = #item{id = Id, code = Code, name = Name, count = Count, time = CurSec},
			ets:insert(item, Item);
		_ -> 
			ok
	end,
	{ok, []}.


item_select(Account) ->
	#account{item_list = ItemList, auth = Auth} = Account,
	AllItem = 
		case Auth of
			0 -> one_shop(ItemList);
			1 -> all_shop()
		end,
	{ok, AllItem}.
	


one_shop(ItemList) ->
	Fun = fun(ItemId, List) ->
			[#item{code = Code,name = Name,count = Count}] 
				= ets:lookup(item, ItemId),
			[[{<<"id">>, ItemId}, {<<"code">>, Code}, {<<"name">>, Name}, {<<"count">>, Count}]|List]
	end,
	lists:foldl(Fun, [], ItemList).


all_shop() ->
	Fun = fun(#account{shop = Name, item_list = IdList}, List) ->
			ItemList = item(IdList),
			[[{<<"shop">>, Name}, {<<"itemList">>, ItemList}]|List]
		end,
	ets:foldl(Fun, [], account).



item(IdList) ->
	item(IdList, []).


item([Id|List], ItemList) ->
	case ets:lookup(item, Id) of
		[#item{code = Code,name = Name,count = Count}] ->
			ItemList1 = [[{<<"id">>, Id}, {<<"code">>, Code}, {<<"name">>, Name}, {<<"count">>, Count}]|ItemList],
			item(List, ItemList1);
		_ ->
			item(List, ItemList)
	end;
item([], ItemList) -> ItemList.


curtime() ->
	{S1,S2,_} = erlang:timestamp(),
	S1 * 1000000 + S2.


id(User) ->
	Mon = date(),
	Id = 
		case ets:lookup(id, User) of
			[{User, Mon, OldId}] -> OldId + 1;
			[] -> 1
		end,
	ets:insert(id, {User, Mon, Id}),
	{Y, H, D} = Mon,
	list_to_binary(io_lib:format("~4.10.0b~2.10.0b~2.10.0b-~6.10.0b", [Y, H, D, Id])).
