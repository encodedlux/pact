const net_server = require("../net/net_server")

const my_state = net_server.my_state

my_state.on(function(data)
	print(data)
end)

while task.wait(1) do
	my_state.set(function(data)
		const new_data = table.clone(data)
		if data.count <= 0 then
			new_data.count = 60
		else
			new_data.count -= 1
		end
		return new_data
	end)
end
