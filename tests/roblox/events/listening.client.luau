const net_client = require("../net/net_client")

net_client.my_event.on(function(num, str)
	print(num, str)
end)
