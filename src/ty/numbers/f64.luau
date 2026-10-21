const create = require("../create")
const constants = require("../../constants")

const DOUBLE = constants.DOUBLE

const writef64, readf64 = buffer.writef64, buffer.readf64

return create<<number>>({
	write = @native function(buff, offset, value)
		writef64(buff, offset, value)
		return DOUBLE
	end,
	read = @native function(buff, offset)
		return DOUBLE, readf64(buff, offset)
	end,
	size = DOUBLE,
})
