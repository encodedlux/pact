const create = require("../create")

return create<<Color3>>({
	write = function(buff, offset, value)
		buffer.writeu8(buff, offset, math.round(value.R * 255))
		buffer.writeu8(buff, offset + 1, math.round(value.G * 255))
		buffer.writeu8(buff, offset + 2, math.round(value.B * 255))
		return 3
	end,
	read = function(buff, offset)
		return 3,
			Color3.fromRGB(
				buffer.readu8(buff, offset),
				buffer.readu8(buff, offset + 1),
				buffer.readu8(buff, offset + 2)
			)
	end,
	write_array = function(buff, offset, colors)
		const len = #colors
		buffer.writeu16(buff, offset, len)
		local pos = offset + 2
		for i = 1, len do
			const c = colors[i]
			buffer.writeu8(buff, pos, math.round(c.R * 255))
			buffer.writeu8(buff, pos + 1, math.round(c.G * 255))
			buffer.writeu8(buff, pos + 2, math.round(c.B * 255))
			pos += 3
		end
		return pos - offset
	end,
	read_array = function(buff, offset)
		const len = buffer.readu16(buff, offset)
		const value = table.create<<Color3>>(len)
		local pos = offset + 2
		for i = 1, len do
			const r, g, b = buffer.readu8(buff, pos), buffer.readu8(buff, pos + 1), buffer.readu8(buff, pos + 2)
			value[i] = Color3.fromRGB(r, g, b)
			pos += 3
		end
		return pos - offset, value
	end,
	size = 3,
})
