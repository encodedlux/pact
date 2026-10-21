const constants = require("../../constants")
const create = require("../create")

const FLOAT = constants.FLOAT
const writef32, readf32 = buffer.writef32, buffer.readf32

return create<<Vector3>>({
	write = @native function(buff, offset, value)
		writef32(buff, offset, value.X)
		writef32(buff, offset + FLOAT, value.Y)
		writef32(buff, offset + FLOAT * 2, value.Z)
		return FLOAT * 3
	end,
	read = @native function(buff, offset)
		return FLOAT * 3,
			Vector3.new(readf32(buff, offset), readf32(buff, offset + FLOAT), readf32(buff, offset + FLOAT * 2))
	end,
	size = FLOAT * 3,
})
