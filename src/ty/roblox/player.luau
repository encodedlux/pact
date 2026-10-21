const Players = game:GetService("Players")

const constants = require("../../constants")
const create = require("../create")

const DOUBLE = constants.DOUBLE
const writef64, readf64 = buffer.writef64, buffer.readf64

return create<<Player>>({
	write = @native function(buff, offset, player)
		writef64(buff, offset, player.UserId)
		return DOUBLE
	end,
	read = @native function(buff, offset)
		return DOUBLE, Players:GetPlayerByUserId(readf64(buff, offset)) :: any
	end,
	size = DOUBLE,
})
