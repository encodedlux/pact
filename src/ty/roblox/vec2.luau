const constants = require("../../constants")
const create = require("../create")

const FLOAT = constants.FLOAT

const writef32, readf32 = buffer.writef32, buffer.readf32

return create<<Vector2>>({
	write = @native function(buff, offset, value)
		writef32(buff, offset, value.X)
		writef32(buff, offset + FLOAT, value.Y)
		return FLOAT * 2
	end,
	read = @native function(buff, offset)
		return FLOAT * 2, Vector2.new(readf32(buff, offset), readf32(buff, offset + FLOAT))
	end,
	size = FLOAT * 2,
})
