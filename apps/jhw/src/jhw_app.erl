%%%-------------------------------------------------------------------
%% @doc jhw public API
%% @end
%%%-------------------------------------------------------------------

-module(jhw_app).

-include("jhw.hrl").

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
	{ok, Sup} = jhw_sup:start_link(),
	ok = cache(),
	ok = load(),
	Dispatch = cowboy_router:compile([
		{'_', [
			{"/buy", jhw_html_buy, []},
			{"/sell", jhw_html_sell, []},
			{"/", jhw_main, []},
			{"/admin/login", jhw_admin_login, []},
			{"/admin/update", jhw_admin_update, []},
			{"/user/add", jhw_user_add, [jhw_auth]},
			{"/user/del", jhw_user_del, [jhw_auth]},
			{"/user/login", jhw_user_login, []},
			{"/user/update", jhw_user_update, []},
			{"/user/push", jhw_user_push, []},
			{"/captcha", jhw_captcha, [jhw_auth]},
			{"/mall", jhw_mall, [jhw_auth]},
			{"/mall/add", jhw_mall_add, [jhw_auth]},
			{"/mall/del", jhw_mall_del, [jhw_auth]},
			{"/supplier/add", jhw_supplier_add, [jhw_auth]},
			{"/supplier/del", jhw_supplier_del, [jhw_auth]},
			{"/stock", jhw_stock, [jhw_auth]},
			{"/stock/add", jhw_stock_add, [jhw_auth]},
			{"/stock/update", jhw_stock_update, [jhw_auth]},
			{"/search", jhw_search, [jhw_auth]},
			{"/profit", jhw_profit, [jhw_auth]},
			{"/upload/buy", jhw_upload_buy, []},
			{"/upload/sell", jhw_upload_sell, []},
			{"/price", jhw_price, [jhw_auth]},
			{"/purchase", jhw_purchase, [jhw_auth]},
			{"/update", jhw_update, [jhw_auth]},
			{"/ios", cowboy_static, {priv_file, jhw, "jhw.ipa"}}
		]}
	]),
	{ok, _} = cowboy:start_clear(http, [{port, 9999}], #{
		env => #{dispatch => Dispatch}
	}),
    {ok, Sup}.

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================


cache() ->
	ets:new(admin, [named_table, public, {keypos, #admin.id}]),
	ets:new(mall, [named_table, public, {keypos, #mall.id}]),
	ets:new(supplier, [named_table, public, {keypos, #supplier.id}]),
	ets:new(html, [named_table, public, {keypos, #html.key}]),
	ok.




load() ->
	{ok, _, MallList} = jhw_sql:run(<<"select * from mall">>),
	[ets:insert(mall, #mall{id=Id, name=Name}) || [Id, Name] <- MallList],

	{ok, _, Supplier} = jhw_sql:run(<<"select * from supplier">>),
	[ets:insert(supplier, #supplier{id=Id, name=Name}) || [Id, Name] <- Supplier],

	jhw_html:mall(),
	ok.




	



