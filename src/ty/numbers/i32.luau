const create = require("../create")
const constants = require("../../constants")

const INTEGER = constants.INTEGER

const writei32, readi32 = buffer.writei32, buffer.readi32

return create<<number>>({
	write = @native function(buff, offset, value)
		writei32(buff, offset, value)
		return INTEGER
	end,
	read = @native function(buff, offset)
		return INTEGER, readi32(buff, offset)
	end,
	size = INTEGER,
})
