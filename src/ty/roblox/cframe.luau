const constants = require("../../constants")
const create = require("../create")

const FLOAT = constants.FLOAT
const writef32, readf32 = buffer.writef32, buffer.readf32

return create<<CFrame>>({
	write = @native function(buff, offset, value)
		local x, y, z = value.X, value.Y, value.Z
		local axis, angle = value:ToAxisAngle()
		axis *= angle
		local rx, ry, rz = axis.X, axis.Y, axis.Z

		writef32(buff, offset, x)
		writef32(buff, offset + FLOAT, y)
		writef32(buff, offset + FLOAT * 2, z)
		writef32(buff, offset + FLOAT * 3, rx)
		writef32(buff, offset + FLOAT * 4, ry)
		writef32(buff, offset + FLOAT * 5, rz)

		return FLOAT * 6
	end,
	read = @native function(buff, offset)
		local x = readf32(buff, offset)
		local y = readf32(buff, offset + FLOAT)
		local z = readf32(buff, offset + FLOAT * 2)
		local rx = readf32(buff, offset + FLOAT * 3)
		local ry = readf32(buff, offset + FLOAT * 4)
		local rz = readf32(buff, offset + FLOAT * 5)

		local axis = Vector3.new(rx, ry, rz)
		local angle = axis.Magnitude

		return FLOAT * 6,
			if angle ~= 0 then CFrame.new(x, y, z) * CFrame.fromAxisAngle(axis, angle) else CFrame.new(x, y, z)
	end,
	size = FLOAT * 6,
})
