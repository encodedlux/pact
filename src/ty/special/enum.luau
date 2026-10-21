const create = require("../create")
const constants = require("../../constants")

const BYTE = constants.BYTE

const writeu8, readu8 = buffer.writeu8, buffer.readu8

type function enum_type(ty: type): type
	assert(ty:is("singleton"), "Enum must be a singleton type")
	const values = string.split(ty:value() :: string, ", ")
	local union = nil
	for i = 1, #values do
		const value_ty = types.singleton(values[i])
		union = if union then types.unionof(union, value_ty) else value_ty
	end
	return if union then union else types.singleton(nil)
end

const function enum<T>(comma_string: T | "")
	const values = string.split(comma_string, ", ")
	const value_map: { [string]: number } = {}
	for i = 1, #values do
		value_map[values[i]] = i
	end

	return create<<enum_type<T>>>({
		write = @native function(buff, offset, value, refs)
			writeu8(buff, offset, value_map[value])
			return BYTE
		end,
		read = @native function(buff, offset, refs)
			return BYTE, values[readu8(buff, offset)] :: any
		end,
		size = BYTE,
	})
end

return enum
