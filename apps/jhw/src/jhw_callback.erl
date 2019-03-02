-module(jhw_callback).


-export([handle/2]).



handle([Mod|List], Req) ->
	case Mod:handle(Req) of
		ok -> handle(List, Req);
		Error -> Error
	end;
handle([], _Req) -> ok.



