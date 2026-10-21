const net_client = require("../net/net_client")

const my_state = net_client.my_state

const select_doubled_count = my_state.selector(function(data)
	return data.count
end, function(count: number)
	return count * 2
end)

my_state.on(select_doubled_count, function(count, prev_count)
	print(count, prev_count)
end)
