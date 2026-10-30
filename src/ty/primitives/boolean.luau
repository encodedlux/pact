const create = require("../create")

return create<<boolean>>({
	write = function(buff, offset, value)
		buffer.writeu8(buff, offset, value and 1 or 0)
		return 1
	end,
	read = function(buff, offset)
		return 1, buffer.readu8(buff, offset) == 1
	end,
	size = 1,
	write_array = function(buff, offset, value)
		const len = #value
		const byte_len = math.floor((len + 7) / 8)
		buffer.writeu16(buff, offset, len)
		local pos = offset + 2
		for i = 0, byte_len - 1 do
			const start_idx = i * 8 + 1
			const end_idx = math.min(start_idx + 7, len)
			local byte = 0
			for j = start_idx, end_idx do
				if value[j] then
					byte = bit32.bor(byte, bit32.lshift(1, (j - 1) % 8))
				end
			end
			buffer.writeu8(buff, pos + i, byte)
		end
		return 2 + byte_len
	end,
	read_array = function(buff, offset)
		const len = buffer.readu16(buff, offset)
		const value = table.create<<boolean>>(len)
		local pos = offset + 2
		const byte_len = math.floor((len + 7) / 8)
		for i = 0, byte_len - 1 do
			const start_idx = i * 8 + 1
			const end_idx = math.min(start_idx + 7, len)
			local byte = buffer.readu8(buff, pos + i)
			for j = start_idx, end_idx do
				value[j] = bit32.band(bit32.rshift(byte, (j - 1) % 8), 1) ~= 0
			end
		end
		return 2 + byte_len, value
	end,
	size_array = function(value)
		return 2 + math.floor((#value + 7) / 8)
	end,
	parse = function(value)
		if typeof(value) ~= "boolean" then
			return false, "value must be a boolean"
		end
		return true, nil
	end,
})
