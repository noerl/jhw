-module(jhw_supplier_add).

-include("jhw.hrl").

-export([init/2, handle/1]).

init(Req0, Opts) ->
	NewReq = jhw_callback:handle(?MODULE, Opts, Req0),
	{ok, NewReq, Opts}.


handle(#{id := Uid, body := Body}) ->
	PostList = jsx:decode(Body),
	Name = proplists:get_value(<<"name">>, PostList),
    Sql = io_lib:format("insert into supplier(`name`) values ('~s')", [Name]),
    case jhw_sql:insert(Sql) of
        {ok, Id} ->
            ets:insert(supplier, #supplier{id = Id, name = Name}),
			MsgList = [{<<"id">>, Id}, {<<"name">>, Name}],
			MsgBin = jsx:encode([{<<"status">>, <<"ok">>}, {<<"supplierAdd">>,MsgList}]),
			jhw_update:broadcast(Uid, [{<<"cmd">>, <<"supplierAdd">>}, {<<"data">>, MsgList}]),
            {ok, MsgBin};
        _ ->
            {error, 1005}
    end.





