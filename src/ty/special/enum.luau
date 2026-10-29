const create = require("../create")

type function enum_infer(ty: type): type
	assert(ty:is("singleton"), "Enum must be a singleton type")
	const values = string.split(ty:value() :: string, ", ")
	local union = nil
	for i = 1, #values do
		const value_ty = types.singleton(values[i])
		union = if union then types.unionof(union, value_ty) else value_ty
	end
	return if union then union else types.singleton(nil)
end

type function auto_complete_comma(ty: type)
	if ty.tag == "union" then
		for _, v in ty:components() do
			if v.tag == "singleton" then
				ty = v
				break
			end
		end
	end
	const value = ty:value()
	const values = string.split(value :: string, ", ")
	if #values < 2 then
		error(`Enum values have to be separated by ", "`)
	end
	return types.unionof(ty, types.singleton(`{value}, `))
end

const function enum<T>(comma_string: T | "" | auto_complete_comma<T>)
	const values = string.split(comma_string, ", ")
	const value_map: { [string]: number } = {}
	for i = 1, #values do
		value_map[values[i]] = i
	end

	return create<<enum_infer<T>>>({
		write = function(buff, offset, value, refs)
			buffer.writeu8(buff, offset, value_map[value])
			return 1
		end,
		read = function(buff, offset, refs)
			return 1, values[buffer.readu8(buff, offset)] :: any
		end,
		write_array = function(buff, offset, value)
			const len = #value
			buffer.writeu16(buff, offset, len)
			local pos = offset + 2
			for i = 1, len do
				buffer.writeu8(buff, pos, value_map[value[i]])
				pos += 1
			end
			return pos - offset
		end,
		read_array = function(buff, offset)
			const len = buffer.readu16(buff, offset)
			const value = table.create<<any>>(len)
			local pos = offset + 2
			for i = 1, len do
				value[i] = values[buffer.readu8(buff, pos)]
				pos += 1
			end
			return pos - offset, value
		end,
		size = 1,
	})
end

return enum
