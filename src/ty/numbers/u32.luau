const constants = require("../../constants")
const create = require("../create")

const INTEGER = constants.INTEGER

return create<<number>>({
	write = function(buff, offset, value)
		buffer.writeu32(buff, offset, value)
		return INTEGER
	end,
	read = function(buff, offset)
		return INTEGER, buffer.readu32(buff, offset)
	end,
	write_array = function(buff, offset, value)
		const len = #value
		buffer.writeu16(buff, offset, len)
		local pos = offset + 2
		for i = 1, len do
			buffer.writeu32(buff, pos, value[i])
			pos += INTEGER
		end
		return pos - offset
	end,
	read_array = function(buff, offset)
		const len = buffer.readu16(buff, offset)
		const value = table.create<<number>>(len)
		local pos = offset + 2
		for i = 1, len do
			value[i] = buffer.readu32(buff, pos)
			pos += INTEGER
		end
		return pos - offset, value
	end,
	size = INTEGER,
})
