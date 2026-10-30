const constants = require("../../constants")
const create = require("../create")
const range = require("./range")

const INTEGER = constants.INTEGER

return create<<number>>({
	write = function(buff, offset, value)
		buffer.writei32(buff, offset, value)
		return INTEGER
	end,
	read = function(buff, offset)
		return INTEGER, buffer.readi32(buff, offset)
	end,
	write_array = function(buff, offset, value)
		const len = #value
		buffer.writeu16(buff, offset, len)
		local pos = offset + 2
		for i = 1, len do
			buffer.writei32(buff, pos, value[i])
			pos += INTEGER
		end
		return pos - offset
	end,
	read_array = function(buff, offset)
		const len = buffer.readu16(buff, offset)
		const value = table.create<<number>>(len)
		local pos = offset + 2
		for i = 1, len do
			value[i] = buffer.readi32(buff, pos)
			pos += INTEGER
		end
		return pos - offset, value
	end,
	size = INTEGER,
	parse = range.parse_integer({ min = -2_147_483_648, max = 2_147_483_647 }),
})
