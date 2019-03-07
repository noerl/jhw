-module(jhw_admin_update).
-include("jhw.hrl").


-export([init/2, handle/1]).


init(Req0, Opts) ->
	NewReq = jhw_callback:handle(?MODULE, Opts, Req0),
	{ok, NewReq, Opts}.




handle(#{id := Uid, body := Body}) ->
    PostList = jsx:decode(Body),
	Pwd = proplists:get_value(<<"pwd">>, PostList),
    Sql = io_lib:format("update admin set `pwd` = '~s' where `id` = '~p'", [Pwd, Uid]),
    case jhw_sql:run(Sql) of
        ok ->
			ets:delete(admin, Uid),
			MsgBin = jsx:encode([{<<"status">>, <<"ok">>}]),
            {ok, MsgBin};
        _ ->
            {error, 1005}
    end.
            
	








