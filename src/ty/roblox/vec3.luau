const create = require("../create")

return create<<Vector3>>({
	write = function(buff, offset, value)
		local x, y, z = value.X, value.Y, value.Z
		buffer.writef32(buff, offset, if x == x and x ~= math.huge and x ~= -math.huge then x else 0)
		buffer.writef32(buff, offset + 4, if y == y and y ~= math.huge and y ~= -math.huge then y else 0)
		buffer.writef32(buff, offset + 8, if z == z and z ~= math.huge and z ~= -math.huge then z else 0)
		return 12
	end,
	read = function(buff, offset)
		local x, y, z = buffer.readf32(buff, offset), buffer.readf32(buff, offset + 4), buffer.readf32(buff, offset + 8)
		return 12,
			Vector3.new(
				if x == x and x ~= math.huge and x ~= -math.huge then x else 0,
				if y == y and y ~= math.huge and y ~= -math.huge then y else 0,
				if z == z and z ~= math.huge and z ~= -math.huge then z else 0
			)
	end,
	write_array = function(buff, offset, value)
		const len = #value
		buffer.writeu16(buff, offset, len)
		local pos = offset + 2
		for i = 1, len do
			const v = value[i]
			const x, y, z = v.X, v.Y, v.Z
			buffer.writef32(buff, pos, if x == x and x ~= math.huge and x ~= -math.huge then x else 0)
			buffer.writef32(buff, pos + 4, if y == y and y ~= math.huge and y ~= -math.huge then y else 0)
			buffer.writef32(buff, pos + 8, if z == z and z ~= math.huge and z ~= -math.huge then z else 0)
			pos += 12
		end
		return pos - offset
	end,
	read_array = function(buff, offset)
		const len = buffer.readu16(buff, offset)
		const value = table.create<<Vector3>>(len)
		local pos = offset + 2
		for i = 1, len do
			const x, y, z = buffer.readf32(buff, pos), buffer.readf32(buff, pos + 4), buffer.readf32(buff, pos + 8)
			value[i] = Vector3.new(
				if x == x and x ~= math.huge and x ~= -math.huge then x else 0,
				if y == y and y ~= math.huge and y ~= -math.huge then y else 0,
				if z == z and z ~= math.huge and z ~= -math.huge then z else 0
			)
			pos += 12
		end
		return pos - offset, value
	end,
	size = 12,
	parse = function(value)
		if typeof(value) ~= "Vector3" then
			return false, "value must be a Vector3"
		end
		return true, nil
	end,
})
