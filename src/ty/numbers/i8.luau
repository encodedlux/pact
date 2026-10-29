const constants = require("../../constants")
const create = require("../create")

const BYTE = constants.BYTE

return create<<number>>({
	write = function(buff, offset, value)
		buffer.writei8(buff, offset, value)
		return BYTE
	end,
	read = function(buff, offset)
		return BYTE, buffer.readi8(buff, offset)
	end,
	write_array = function(buff, offset, value)
		const len = #value
		buffer.writeu16(buff, offset, len)
		local pos = offset + 2
		for i = 1, len do
			buffer.writei8(buff, pos, value[i])
			pos += BYTE
		end
		return pos - offset
	end,
	read_array = function(buff, offset)
		const len = buffer.readu16(buff, offset)
		const value = table.create<<number>>(len)
		local pos = offset + 2
		for i = 1, len do
			value[i] = buffer.readi8(buff, pos)
			pos += BYTE
		end
		return pos - offset, value
	end,
	size = BYTE,
})
