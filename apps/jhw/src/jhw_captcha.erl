-module(jhw_captcha).
-include("jhw.hrl").



-export([init/2]).


init(Req0, Opts) ->
	RespBody = handle(Opts, Req0),
	NewReq = cowboy_req:reply(200, #{
		<<"content-type">> => <<"application/json; charset=utf-8">>
	}, RespBody, Req0),
	{ok, NewReq, Opts}.



handle(CallList, Req) ->
	case resp(CallList, Req) of
		{ok, RespBody} -> RespBody;
		{error, ErrorCode} ->
			jsx:encode([
				{<<"status">>, <<"error">>},
				{<<"code">>, ErrorCode}
			])
	end.


resp(CallList, Req) ->
	case jhw_callback:handle(CallList, Req) of
		ok -> 
			handle(Req);
		Error ->
			Error
	end.


handle(_Req) ->
    Uid = get('$uid'),
    CurTime = jhw_util:curtime(),
    case ets:lookup(user, Uid) of
        [User] -> 
            Captcha = 
                case (User#user.captchaTime =/= undefined) andalso (User#user.captchaTime < CurTime + 60) of 
                    true -> 
                        User#user.captcha;
                    false ->
                        CaptchaTmp = jhw_util:captcha(),
                        ets:insert(user, User#user{captcha = CaptchaTmp, captchaTime = CurTime}),
                        CaptchaTmp
                end,
            {ok, jsx:encode([{<<"status">>, <<"ok">>},{<<"captcha">>, Captcha}])};
        _ ->
            {error, 1006}
    end.
            
	








