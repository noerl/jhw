-module(jhw_html_buy).


-export([init/2]).

init(Req, Opts) ->
	RespBody = jhw_html:buy(),
	NewReq = cowboy_req:reply(200, #{
		<<"content-type">> => <<"text/html; charset=utf-8">>
	}, RespBody, Req),
	{ok, NewReq, Opts}.