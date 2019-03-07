-module(jhw_user_add).

-include("jhw.hrl").

-export([init/2, handle/1]).

init(Req0, Opts) ->
	NewReq = jhw_callback:handle(?MODULE, Opts, Req0),
	{ok, NewReq, Opts}.





handle(#{id := Uid, body := Body}) ->
	PostList = jsx:decode(Body),
    Phone = proplists:get_value(<<"phone">>, PostList),
    Pwd = proplists:get_value(<<"pwd">>, PostList),
    Name = proplists:get_value(<<"name">>, PostList),
    Mall = proplists:get_value(<<"mid">>, PostList),
    Sql = io_lib:format("insert into user(`phone`,`pwd`,`name`,`mid`) values ('~s','~s','~s','~p')", [Phone, Pwd, Name, Mall]),
    case jhw_sql:insert(Sql) of
        {ok, Id} ->
            ets:insert(mall, #mall{id = Id, name = Name}),
			jhw_html:mall(),
			MsgList = [{<<"id">>, Id}, {<<"name">>, Name}],
			MsgBin = jsx:encode([{<<"status">>, <<"ok">>}, {<<"mallAdd">>, MsgList}]),
			jhw_update:broadcast(Uid, [{<<"cmd">>, <<"mallAdd">>}, {<<"data">>, MsgList}]),
            {ok, MsgBin};
        _ ->
            {error, 1005}
    end.





