const RunService = game:GetService("RunService")

const net_server = require("../net/net_server")

const iter_other = net_server.other.collect()

RunService.Heartbeat:Connect(function()
	for index, player, num, str in iter_other do
		print(index, player, num, str)
	end
end)
