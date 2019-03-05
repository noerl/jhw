-module(jhw_supplier_del).

-include("jhw.hrl").

-export([init/2, handle/1]).

init(Req0, Opts) ->
	NewReq = jhw_callback:handle(?MODULE, Opts, Req0),
	{ok, NewReq, Opts}.


handle(#{id := Uid, body := Body}) ->
	PostList = jsx:decode(Body),
	Id = proplists:get_value(<<"id">>, PostList),
    Sql = io_lib:format("delete from supplier where `id` = '~p'", [Id]),
    case jhw_sql:run(Sql) of
        ok ->
            ets:delete(supplier, Id),
			MsgList =  [{<<"id">>, Id}],
			MsgBin = jsx:encode([{<<"status">>, <<"ok">>},{<<"supplierDel">>, MsgList}]),
			jhw_update:broadcast(Uid, [{<<"cmd">>, <<"supplierDel">>}, {<<"data">>, MsgList}]),
            {ok, MsgBin};
        _ ->
            {error, 1005}
    end.





