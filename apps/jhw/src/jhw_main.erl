-module(jhw_main).

-export([init/2]).

init(Req0, Opts) ->
	Req = cowboy_req:reply(200, #{
		<<"content-type">> => <<"text/plain; charset=utf-8">>
	}, <<"jhw server is running!">>, Req0),
	{ok, Req, Opts}.
