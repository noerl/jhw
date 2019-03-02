-module(jhw_util).

-include("jhw.hrl").


-export([
	md5/1,
	curtime/0,
	cur_mon/0,
	last_mon/0,
	binary_to_num/1,
	captcha/0
]).


binary_to_num(Bin) ->
	binary_to_num(Bin, 0).



binary_to_num(<<A,Bin/binary>>, Num) when A >= $0 andalso A =< $9 ->
	binary_to_num(Bin, (Num*10) + A-$0);
binary_to_num(<<$., A, _Bin/binary>>, Num) ->
	Num + ((A-$0) / 10);
binary_to_num(<<>>, Num) -> Num.




md5(Str) ->
	list_to_binary([io_lib:format("~2.16.0b", [C]) || <<C>> <= erlang:md5(Str)]).



curtime() ->
	{S1,S2,_S3} = erlang:timestamp(),
	S1 * 1000000 + S2.


last_mon() ->
	Time = curtime() - 86400 * 30,
	{{Y,M,D},{HH,MM,SS}} = calendar:gregorian_seconds_to_datetime(Time+62167248000),
	io_lib:format("~4.10.0B-~2.10.0B-~2.10.0B ~2.10.0B:~2.10.0B:~2.10.0B", [Y,M,D, HH,MM,SS]).

cur_mon() ->
	{Y, M, _D} = date(),
	Y*100 + M.



captcha() ->
	list_to_binary(io_lib:format("~6.10.0B", [rand:uniform(999999)])).
	
