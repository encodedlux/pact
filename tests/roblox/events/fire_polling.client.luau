const net_client = require("../net/net_client")

while task.wait() do
	net_client.other.fire(7, "hello")
end
