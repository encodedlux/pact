const create = require("../create")

return create<<Vector2>>({
	write = function(buff, offset, value)
		const x, y = value.X, value.Y
		buffer.writef32(buff, offset, if x == x and x ~= math.huge and x ~= -math.huge then x else 0)
		buffer.writef32(buff, offset + 4, if y == y and y ~= math.huge and y ~= -math.huge then y else 0)
		return 8
	end,
	read = function(buff, offset)
		const x, y = buffer.readf32(buff, offset), buffer.readf32(buff, offset + 4)
		return 8,
			Vector2.new(
				if x == x and x ~= math.huge and x ~= -math.huge then x else 0,
				if y == y and y ~= math.huge and y ~= -math.huge then y else 0
			)
	end,
	write_array = function(buff, offset, value)
		const len = #value
		buffer.writeu16(buff, offset, len)
		local pos = offset + 2
		for i = 1, len do
			const v = value[i]
			const x, y = v.X, v.Y
			buffer.writef32(buff, pos, if x == x and x ~= math.huge and x ~= -math.huge then x else 0)
			buffer.writef32(buff, pos + 4, if y == y and y ~= math.huge and y ~= -math.huge then y else 0)
			pos += 8
		end
		return pos - offset
	end,
	read_array = function(buff, offset)
		const len = buffer.readu16(buff, offset)
		const value = table.create<<Vector2>>(len)
		local pos = offset + 2
		for i = 1, len do
			const x, y = buffer.readf32(buff, pos), buffer.readf32(buff, pos + 4)
			value[i] = Vector2.new(
				if x == x and x ~= math.huge and x ~= -math.huge then x else 0,
				if y == y and y ~= math.huge and y ~= -math.huge then y else 0
			)
			pos += 8
		end
		return pos - offset, value
	end,
	size = 8,
})
