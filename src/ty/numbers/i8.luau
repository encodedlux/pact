const create = require("../create")
const constants = require("../../constants")

const BYTE = constants.BYTE

const writei8, readi8 = buffer.writei8, buffer.readi8

return create<<number>>({
	write = @native function(buff, offset, value)
		writei8(buff, offset, value)
		return BYTE
	end,
	read = @native function(buff, offset)
		return BYTE, readi8(buff, offset)
	end,
	size = BYTE,
})
