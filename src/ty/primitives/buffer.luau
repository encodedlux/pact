const create = require("../create")
const constants = require("../../constants")

const SHORT = constants.SHORT

const buffer_len, buffer_copy, buffer_create, writeu16, readu16 =
	buffer.len, buffer.copy, buffer.create, buffer.writeu16, buffer.readu16

return create<<buffer>>({
	write = @native function(buff, offset, value)
		const len = buffer_len(value)
		writeu16(buff, offset, len)
		buffer_copy(buff, offset + SHORT, value, 0, len)
		return SHORT + len
	end,
	read = @native function(buff, offset)
		const len = readu16(buff, offset)
		local new_buff = buffer_create(len)
		buffer_copy(new_buff, 0, buff, offset + SHORT, len)
		return SHORT + len, new_buff
	end,
	size = @native function(value: buffer)
		return SHORT + buffer_len(value)
	end,
})
