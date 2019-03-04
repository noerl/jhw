-module(jhw_callback).


-export([handle/3]).



handle(FromMod, ModList, Req) ->
	handle(FromMod, ModList, Req, #{}).

handle(FromMod, [Mod|List], Req, Map) ->
	case Mod:handle(Req, Map) of
		{ok, NewMap} -> handle(FromMod, List, Req, NewMap);
		{error, ErrorCode} -> handle_error(Req, ErrorCode)
	end;
handle(FromMod, [], Req, Map) -> 
	case FromMod:handle(Map) of
		{ok, RespBody} -> jhw_auth:resp(Req, RespBody);
		{error, ErrorCode} -> handle_error(Req, ErrorCode)
	end.






handle_error(Req, ErrorCode) ->
	Body = jsx:encode([
				{<<"status">>, <<"error">>},
				{<<"code">>, ErrorCode}
			]),
	jhw_auth:resp(Req, Body).



