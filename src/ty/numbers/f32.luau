const create = require("../create")
const constants = require("../../constants")

const FLOAT = constants.FLOAT

const writef32, readf32 = buffer.writef32, buffer.readf32

return create<<number>>({
	write = @native function(buff, offset, value)
		writef32(buff, offset, value)
		return FLOAT
	end,
	read = @native function(buff, offset)
		return FLOAT, readf32(buff, offset)
	end,
	size = FLOAT,
})
