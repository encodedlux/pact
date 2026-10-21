const constants = require("../../constants")
const create = require("../create")

const BYTE = constants.BYTE

const writeu8, readu8 = buffer.writeu8, buffer.readu8

return create<<Color3>>({
	write = @native function(buff, offset, value)
		writeu8(buff, offset, math.round(value.R * 255))
		writeu8(buff, offset + 1, math.round(value.G * 255))
		writeu8(buff, offset + 2, math.round(value.B * 255))
		return BYTE * 3
	end,
	read = @native function(buff, offset)
		return BYTE * 3, Color3.fromRGB(readu8(buff, offset), readu8(buff, offset + 1), readu8(buff, offset + 2))
	end,
	size = BYTE * 3,
})
