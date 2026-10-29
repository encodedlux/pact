const constants = require("../../constants")
const create = require("../create")

const FLOAT = constants.FLOAT

return create<<number>>({
	write = function(buff, offset, value)
		buffer.writef32(
			buff,
			offset,
			if value == value and value ~= math.huge and value ~= -math.huge then value else 0
		)
		return FLOAT
	end,
	read = function(buff, offset)
		const value = buffer.readf32(buff, offset)
		return FLOAT, if value == value and value ~= math.huge and value ~= -math.huge then value else 0
	end,
	write_array = function(buff, offset, value)
		const len = #value
		buffer.writeu16(buff, offset, len)
		local pos = offset + 2
		for i = 1, len do
			const v = value[i]
			buffer.writef32(buff, pos, if v == v and v ~= math.huge and v ~= -math.huge then v else 0)
			pos += FLOAT
		end
		return pos - offset
	end,
	read_array = function(buff, offset)
		const len = buffer.readu16(buff, offset)
		const value = table.create<<number>>(len)
		local pos = offset + 2
		for i = 1, len do
			const v = buffer.readf32(buff, pos)
			value[i] = if v == v and v ~= math.huge and v ~= -math.huge then v else 0
			pos += FLOAT
		end
		return pos - offset, value
	end,
	size = FLOAT,
})
