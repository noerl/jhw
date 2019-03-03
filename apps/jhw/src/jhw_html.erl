-module(jhw_html).
-include("jhw.hrl").

-export([buy/0,sell/0,mall/0]).


buy() ->
    {ok, Bin} = file:read_file(code:priv_dir(jhw) ++ "/buy.html"),
    char_begin(Bin).

sell() ->
    {ok, Bin} = file:read_file(code:priv_dir(jhw) ++ "/sell.html"),
    char_begin(Bin).



char_begin(Bin) ->
    char_begin(Bin, <<>>).
    
char_begin(<<"${", Bin/binary>>, Top) ->
    case char_end(Bin) of
        {ok, Key, Bottom} ->
            NewTop =
                case ets:lookup(html, Key) of
                    [#html{value = Value}] -> 
                        <<Top/binary, Value/binary>>;
                    _ ->
                        <<Top/binary, <<"${">>/binary, Key/binary, <<"}">>/binary>>
                end,
            char_begin(Bottom, NewTop);
        Bottom ->
            <<Top/binary, <<"${">>/binary, Bottom/binary>>
    end;
char_begin(<<C, Bin/binary>>, Top) ->
    char_begin(Bin, <<Top/binary, C>>);
char_begin(<<>>, Top) -> Top.

char_end(Bin) ->
    char_end(Bin, <<>>).

char_end(<<"}", Bin/binary>>, Key) ->
    {ok, Key, Bin};
char_end(<<C, Bin/binary>>, Key) ->
    char_end(Bin, <<Key/binary, C>>);
char_end(<<>>, Bin) -> Bin.




mall() ->
	mall(ets:tab2list(mall), "").

mall([{mall, Id, Name}|MallList], OptListStr) ->
	OptStr = io_lib:format("<option value=\"~p\">~s</option>", [Id, Name]),
	mall(MallList, OptListStr ++ OptStr);
mall([], OptListStr) -> 
	ets:insert(html, #html{key = <<"option">>, value = list_to_binary(OptListStr)}).