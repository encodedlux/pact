const constants = require("../../constants")
const create = require("../create")

const SHORT = constants.SHORT

return create<<number>>({
	write = function(buff, offset, value)
		buffer.writeu16(buff, offset, value)
		return SHORT
	end,
	read = function(buff, offset)
		return SHORT, buffer.readu16(buff, offset)
	end,
	write_array = function(buff, offset, value)
		const len = #value
		buffer.writeu16(buff, offset, len)
		local pos = offset + 2
		for i = 1, len do
			buffer.writeu16(buff, pos, value[i])
			pos += SHORT
		end
		return pos - offset
	end,
	read_array = function(buff, offset)
		const len = buffer.readu16(buff, offset)
		const value = table.create<<number>>(len)
		local pos = offset + 2
		for i = 1, len do
			value[i] = buffer.readu16(buff, pos)
			pos += SHORT
		end
		return pos - offset, value
	end,
	size = SHORT,
})
