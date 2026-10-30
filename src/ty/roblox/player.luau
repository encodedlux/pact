const Players = game:GetService("Players")

const create = require("../create")

return create<<Player>>({
	write = function(buff, offset, player)
		const id = player.UserId
		buffer.writef64(buff, offset, if id == id and id == math.round(id) then id else 0)
		return 8
	end,
	read = function(buff, offset)
		const id = buffer.readf64(buff, offset)
		return 8, Players:GetPlayerByUserId(if id == id and id == math.round(id) then id else 0) :: Player
	end,
	write_array = function(buff, offset, players)
		const len = #players
		buffer.writeu16(buff, offset, len)
		local pos = offset + 2
		for i = 1, len do
			const player = players[i]
			const id = player.UserId
			buffer.writef64(buff, pos, if id == id and id == math.round(id) then id else 0)
			pos += 8
		end
		return pos - offset
	end,
	read_array = function(buff, offset)
		const len = buffer.readu16(buff, offset)
		const value = table.create<<Player>>(len)
		local pos = offset + 2
		for i = 1, len do
			const id = buffer.readf64(buff, pos)
			value[i] = Players:GetPlayerByUserId(if id == id and id == math.round(id) then id else 0) :: Player
			pos += 8
		end
		return pos - offset, value
	end,
	size = 8,
	parse = function(value)
		if typeof(value) ~= "Instance" or not value:IsA("Player") then
			return false, "value must be a Player"
		end
		return true, nil
	end,
})
