const create = require("../create")

return create<<CFrame>>({
	write = function(buff, offset, value: CFrame)
		const x, y, z = value.X, value.Y, value.Z
		local axis, angle = value:ToAxisAngle()
		axis *= angle
		const rx, ry, rz = axis.X, axis.Y, axis.Z
		buffer.writef32(buff, offset, if x == x and x ~= math.huge and x ~= -math.huge then x else 0)
		buffer.writef32(buff, offset + 4, if y == y and y ~= math.huge and y ~= -math.huge then y else 0)
		buffer.writef32(buff, offset + 8, if z == z and z ~= math.huge and z ~= -math.huge then z else 0)
		buffer.writef32(buff, offset + 12, if rx == rx and rx ~= math.huge and rx ~= -math.huge then rx else 0)
		buffer.writef32(buff, offset + 16, if ry == ry and ry ~= math.huge and ry ~= -math.huge then ry else 0)
		buffer.writef32(buff, offset + 20, if rz == rz and rz ~= math.huge and rz ~= -math.huge then rz else 0)
		return 24
	end,
	read = function(buff, offset)
		const x = buffer.readf32(buff, offset)
		const y = buffer.readf32(buff, offset + 4)
		const z = buffer.readf32(buff, offset + 8)
		const rx = buffer.readf32(buff, offset + 12)
		const ry = buffer.readf32(buff, offset + 16)
		const rz = buffer.readf32(buff, offset + 20)
		const axis = Vector3.new(
			if rx == rx and rx ~= math.huge and rx ~= -math.huge then rx else 0,
			if ry == ry and ry ~= math.huge and ry ~= -math.huge then ry else 0,
			if rz == rz and rz ~= math.huge and rz ~= -math.huge then rz else 0
		)
		const angle = axis.Magnitude
		const cf = CFrame.new(
			if x == x and x ~= math.huge and x ~= -math.huge then x else 0,
			if y == y and y ~= math.huge and y ~= -math.huge then y else 0,
			if z == z and z ~= math.huge and z ~= -math.huge then z else 0
		)
		return 24, if angle ~= 0 then cf * CFrame.fromAxisAngle(axis, angle) else cf
	end,
	write_array = function(buff, offset, value)
		const len = #value
		buffer.writeu16(buff, offset, len)
		local pos = offset + 2
		for i = 1, len do
			const cf = value[i]
			const x, y, z = cf.X, cf.Y, cf.Z
			local axis, angle = cf:ToAxisAngle()
			axis *= angle
			const rx, ry, rz = axis.X, axis.Y, axis.Z
			buffer.writef32(buff, pos, if x == x and x ~= math.huge and x ~= -math.huge then x else 0)
			buffer.writef32(buff, pos + 4, if y == y and y ~= math.huge and y ~= -math.huge then y else 0)
			buffer.writef32(buff, pos + 8, if z == z and z ~= math.huge and z ~= -math.huge then z else 0)
			buffer.writef32(buff, pos + 12, if rx == rx and rx ~= math.huge and rx ~= -math.huge then rx else 0)
			buffer.writef32(buff, pos + 16, if ry == ry and ry ~= math.huge and ry ~= -math.huge then ry else 0)
			buffer.writef32(buff, pos + 20, if rz == rz and rz ~= math.huge and rz ~= -math.huge then rz else 0)
			pos += 24
		end
		return pos - offset
	end,
	read_array = function(buff, offset)
		const len = buffer.readu16(buff, offset)
		const value = table.create<<CFrame>>(len)
		local pos = offset + 2
		for i = 1, len do
			const x = buffer.readf32(buff, pos)
			const y = buffer.readf32(buff, pos + 4)
			const z = buffer.readf32(buff, pos + 8)
			const rx = buffer.readf32(buff, pos + 12)
			const ry = buffer.readf32(buff, pos + 16)
			const rz = buffer.readf32(buff, pos + 20)
			const axis = Vector3.new(
				if rx == rx and rx ~= math.huge and rx ~= -math.huge then rx else 0,
				if ry == ry and ry ~= math.huge and ry ~= -math.huge then ry else 0,
				if rz == rz and rz ~= math.huge and rz ~= -math.huge then rz else 0
			)
			const angle = axis.Magnitude
			const cf = CFrame.new(
				if x == x and x ~= math.huge and x ~= -math.huge then x else 0,
				if y == y and y ~= math.huge and y ~= -math.huge then y else 0,
				if z == z and z ~= math.huge and z ~= -math.huge then z else 0
			)
			value[i] = if angle ~= 0 then cf * CFrame.fromAxisAngle(axis, angle) else cf
			pos += 24
		end
		return pos - offset, value
	end,
	size = 24,
	parse = function(value)
		if typeof(value) ~= "CFrame" then
			return false, "value must be a CFrame"
		end
		return true, nil
	end,
})
