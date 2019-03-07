-module(jhw_captcha).
-include("jhw.hrl").



-export([init/2, handle/1]).


init(Req0, Opts) ->
	NewReq = jhw_callback:handle(?MODULE, Opts, Req0),
	{ok, NewReq, Opts}.




handle(#{id := Uid}) ->
    CurTime = jhw_util:curtime(),
    case ets:lookup(admin, Uid) of
        [Admin] -> 
            Captcha = 
                case (Admin#admin.captchaTime =/= undefined) andalso (Admin#admin.captchaTime < CurTime + 60) of 
                    true -> 
                        Admin#admin.captcha;
                    false ->
                        CaptchaTmp = jhw_util:captcha(),
                        ets:insert(admin, Admin#admin{captcha = CaptchaTmp, captchaTime = CurTime}),
                        CaptchaTmp
                end,
            {ok, jsx:encode([{<<"status">>, <<"ok">>},{<<"captcha">>, Captcha}])};
        _ ->
            {error, 1006}
    end.
            
	








