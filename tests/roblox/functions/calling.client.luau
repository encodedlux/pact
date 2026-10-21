const RunService = game:GetService("RunService")

const net_client = require("../net/net_client")

RunService.PostSimulation:Connect(function()
	const result = net_client.scope.my_func.invoke("foo", true)
	print(result)
end)
