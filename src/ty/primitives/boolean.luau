const create = require("../create")
const constants = require("../../constants")

const BYTE = constants.BYTE

const writeu8, readu8 = buffer.writeu8, buffer.readu8

return create<<boolean>>({
	write = @native function(buff, offset, value)
		writeu8(buff, offset, value and 1 or 0)
		return BYTE
	end,
	read = @native function(buff, offset)
		return BYTE, readu8(buff, offset) == 1
	end,
	size = BYTE,
})
