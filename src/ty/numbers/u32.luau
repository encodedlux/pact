const create = require("../create")
const constants = require("../../constants")

const INTEGER = constants.INTEGER

const writeu32, readu32 = buffer.writeu32, buffer.readu32

return create<<number>>({
	write = @native function(buff, offset, value)
		writeu32(buff, offset, value)
		return INTEGER
	end,
	read = @native function(buff, offset)
		return INTEGER, readu32(buff, offset)
	end,
	size = INTEGER,
})
