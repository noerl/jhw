-module(jhw_login).

-include("jhw.hrl").

-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

init(_Transport, Req, []) ->
	{ok, Req, []}.

handle(Req, State) ->
	{ok, Body, _} = cowboy_req:body(Req),
	DataList = jsx:decode(Body),
	User = proplists:get_value(<<"user">>, DataList),
	Pwd = proplists:get_value(<<"pwd">>, DataList),
	{ok, NewReq} = login(Req, User, Pwd),
	{ok, NewReq, State}.



login(Req, User, Pwd) ->
	case ets:lookup(account, User) of
		[#account{pwd = Pwd} = Account] -> 
			login_ok(Req, Account);
		_ ->
			login_error(Req)
	end.


terminate(_Reason, _Req, _State) ->
	ok.



login_ok(Req, #account{user = User, pwd = Pwd} = Account) ->
	{S1, S2, _S3} = erlang:timestamp(),
	Time = S1 * 1000000 + S2,
	SourceBin = <<(integer_to_binary(Time))/binary, <<"superbin">>/binary, Pwd/binary>>,
	Bin = erlang:md5(SourceBin),
	Id = iolist_to_binary([io_lib:format("~2.16.0b", [V]) || <<V>> <= Bin]),
	Header = [
		{"content-type","application/json"},
		{<<"Access-Control-Allow-Origin">>,<<"*">>},
		{<<"set-cookie">>, <<<<"user=">>/binary, User/binary>>},
		{<<"set-cookie">>, <<<<"aid=">>/binary, Id/binary>>}
	],
	Body = jsx:encode([{<<"state">>, <<"ok">>}, {<<"data">>, []}]),
	ets:insert(account, Account#account{time = Time, id = Id}),
	cowboy_req:reply(200, Header, Body, Req).


login_error(Req) ->
	Body = jsx:encode([{<<"state">>, <<"error">>}]),
	cowboy_req:reply(200, [{"content-type","application/json"},{<<"Access-Control-Allow-Origin">>,<<"*">>}], Body, Req).




