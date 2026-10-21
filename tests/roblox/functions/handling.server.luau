const net_server = require("../net/net_server")

net_server.scope.my_func.on(function(player, value, bool)
	return "bar"
end)
