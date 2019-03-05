-record(user, {
	id,
	pid,
	phone,
	name,
	secret,
	expire,
	captcha,
	captchaTime
}).


-record(mall, {
	id,
	name
}).


-record(supplier, {
	id,
	name
}).

-record(html, {
	key,
	value
}).