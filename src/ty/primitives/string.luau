const create = require("../create")

return create<<string>>({
	write = function(buff, offset, value)
		const len = #value
		buffer.writeu16(buff, offset, len)
		buffer.writestring(buff, offset + 2, value, len)
		return 2 + len
	end,
	read = function(buff, offset)
		const len = buffer.readu16(buff, offset)
		if offset + 2 + len > buffer.len(buff) then
			return 2, ""
		end
		return 2 + len, buffer.readstring(buff, offset + 2, len)
	end,
	write_array = function(buff, offset, value)
		const len = #value
		buffer.writeu16(buff, offset, len)
		local pos = offset + 2
		for i = 1, len do
			const v = value[i]
			const str_len = #v
			buffer.writeu16(buff, pos, str_len)
			buffer.writestring(buff, pos + 2, v, str_len)
			pos += str_len + 2
		end
		return pos - offset
	end,
	read_array = function(buff, offset)
		const len = buffer.readu16(buff, offset)
		const value = table.create<<string>>(len)
		local pos = offset + 2
		for i = 1, len do
			const str_len = buffer.readu16(buff, pos)
			value[i] = buffer.readstring(buff, pos + 2, str_len)
			pos += str_len + 2
		end
		return pos - offset, value
	end,
	size = function(value: string)
		return 2 + #value
	end,
})
