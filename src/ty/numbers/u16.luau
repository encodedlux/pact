const create = require("../create")
const constants = require("../../constants")

const SHORT = constants.SHORT

const writeu16, readu16 = buffer.writeu16, buffer.readu16

return create<<number>>({
	write = @native function(buff, offset, value)
		writeu16(buff, offset, value)
		return SHORT
	end,
	read = @native function(buff, offset)
		return SHORT, readu16(buff, offset)
	end,
	size = SHORT,
})
