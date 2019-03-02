-module(jhw_sql).

-define(SQL_POOL_NAME, sql).

-export([
	run/1,
	run/2,
	run_list/1,
	insert/1,
	transaction/1
]).


run_list(SqlList) ->
	Pid = poolboy:checkout(?SQL_POOL_NAME),
    try 
    	[mysql:query(Pid, Sql) || Sql <- SqlList]
    after
    	ok = poolboy:checkin(?SQL_POOL_NAME, Pid)
	end.


run(Sql) ->
	run(Sql, []).


run(Sql, Args) ->
	poolboy:transaction(?SQL_POOL_NAME, fun(Pid) -> mysql:query(Pid, Sql, Args) end).


transaction(SqlList) ->
	Pid = poolboy:checkout(?SQL_POOL_NAME),
    try 
		mysql:transaction(Pid, fun() -> [ok = mysql:query(Pid, Sql) || Sql <- SqlList] end)
    after
    	ok = poolboy:checkin(?SQL_POOL_NAME, Pid)
	end.

insert(Sql) ->
	Pid = poolboy:checkout(?SQL_POOL_NAME),
    try 
		ok = mysql:query(Pid, Sql),
		{ok, mysql:insert_id(Pid)}
    after
    	ok = poolboy:checkin(?SQL_POOL_NAME, Pid)
	end.
	