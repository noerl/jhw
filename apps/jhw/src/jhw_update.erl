-module(jhw_update).
-include("jhw.hrl").

-export([init/2, handle/1, broadcast/2]).

init(Req0, Opts) ->
	NewReq = jhw_callback:handle(?MODULE, Opts, Req0),
	{ok, NewReq, Opts}.


handle(#{id := Id}) ->
	case ets:lookup(user, Id) of
        [User] -> 
            ets:insert(user, User#user{pid = self()}),
            hold();
        [] -> 
            {error, 12000}
    end.




hold() ->
    receive
        {ok, UpdateInfo} ->
            Msg = jsx:encode([{<<"status">>, <<"ok">>},{<<"update">>, UpdateInfo}]),
            {ok, Msg}
    after 5000 ->
        Msg = jsx:encode([{<<"status">>, <<"ok">>},{<<"update">>, []}]),
        {ok, Msg}
    end.


broadcast(Id, Body) ->
    User = ets:tab2list(user),
    [Pid ! {ok, Body} || #user{id = Uid, pid = Pid} <- User, Uid =/= Id].
        