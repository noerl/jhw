-module(jhw_html_sell).


-export([init/2]).

init(Req, Opts) ->
	RespBody = jhw_html:sell(),
	NewReq = cowboy_req:reply(200, #{
		<<"content-type">> => <<"text/html; charset=utf-8">>
	}, RespBody, Req),
	{ok, NewReq, Opts}.