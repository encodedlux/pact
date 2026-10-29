const create = require("../create")

return create<<buffer>>({
	write = function(buff, offset, value)
		const len = buffer.len(value)
		buffer.writeu16(buff, offset, len)
		buffer.copy(buff, offset + 2, value, 0, len)
		return 2 + len
	end,
	read = function(buff, offset)
		const len = buffer.readu16(buff, offset)
		if offset + 2 + len > buffer.len(buff) then
			return 2, buffer.create(0)
		end
		local new_buff = buffer.create(len)
		buffer.copy(new_buff, 0, buff, offset + 2, len)
		return 2 + len, new_buff
	end,
	size = function(value: buffer)
		return 2 + buffer.len(value)
	end,
})
