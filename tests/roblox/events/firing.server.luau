const net_server = require("../net/net_server")

while task.wait(1) do
	net_server.my_event.fire_all(10, "hello")
end
