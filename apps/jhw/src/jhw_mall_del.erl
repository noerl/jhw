-module(jhw_mall_del).

-include("jhw.hrl").


-export([init/2, handle/1]).

init(Req0, Opts) ->
	NewReq = jhw_callback:handle(?MODULE, Opts, Req0),
	{ok, NewReq, Opts}.





handle(#{body := Body}) ->
	PostList = jsx:decode(Body),
	Id = proplists:get_value(<<"id">>, PostList),
    Sql = io_lib:format("delete from mall where `id` = '~p'", [Id]),
    case jhw_sql:run(Sql) of
        ok ->
            ets:delete(mall, Id),
			jhw_html:mall(),
            {ok, jsx:encode([{<<"status">>, <<"ok">>},{<<"mallDel">>, [{<<"id">>, Id}]}])};
        _ ->
            {error, 1005}
    end.





