-module(jhw_mall_add).

-include("jhw.hrl").

-export([init/2, handle/1]).

init(Req0, Opts) ->
	NewReq = jhw_callback:handle(?MODULE, Opts, Req0),
	{ok, NewReq, Opts}.





handle(#{body := Body}) ->
	PostList = jsx:decode(Body),
	Name = proplists:get_value(<<"name">>, PostList),
    Sql = io_lib:format("insert into mall(`name`) values ('~s')", [Name]),
    case jhw_sql:insert(Sql) of
        {ok, Id} ->
            ets:insert(mall, #mall{id = Id, name = Name}),
			jhw_html:mall(),
            {ok, jsx:encode([{<<"status">>, <<"ok">>},{<<"mallAdd">>, [{<<"id">>, Id}, {<<"name">>, Name}]}])};
        _ ->
            {error, 1005}
    end.





