const create = require("../create")
const constants = require("../../constants")

const SHORT = constants.SHORT

const writei16, readi16 = buffer.writei16, buffer.readi16

return create<<number>>({
	write = @native function(buff, offset, value)
		writei16(buff, offset, value)
		return SHORT
	end,
	read = @native function(buff, offset)
		return SHORT, readi16(buff, offset)
	end,
	size = SHORT,
})
