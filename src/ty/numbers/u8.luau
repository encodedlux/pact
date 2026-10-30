const constants = require("../../constants")
const create = require("../create")
const range = require("./range")

const BYTE = constants.BYTE

return create<<number>>({
	write = function(buff, offset, value)
		buffer.writeu8(buff, offset, value)
		return BYTE
	end,
	read = function(buff, offset)
		return BYTE, buffer.readu8(buff, offset)
	end,
	write_array = function(buff, offset, value)
		const len = #value
		buffer.writeu16(buff, offset, len)
		local pos = offset + 2
		for i = 1, len do
			buffer.writeu8(buff, pos, value[i])
			pos += BYTE
		end
		return pos - offset
	end,
	read_array = function(buff, offset)
		const len = buffer.readu16(buff, offset)
		const value = table.create<<number>>(len)
		local pos = offset + 2
		for i = 1, len do
			value[i] = buffer.readu8(buff, pos)
			pos += BYTE
		end
		return pos - offset, value
	end,
	size = BYTE,
	parse = range.parse_integer({ min = 0, max = 255 }),
})
