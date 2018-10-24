-record(account, {
	user,
	pwd,
	time,
	id,
	auth = 0,
	shop = <<>>,
	item_list = []
}).



-record(item, {
	id,
	code,
	name,
	count,
	time
}).