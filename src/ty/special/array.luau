const constants = require("../../constants")
const create = require("../create")
const types = require("../../types")

type DataType<T> = types.DataType<T>
type Infer<T> = types.Infer<T>

const SHORT = constants.SHORT

const function array<T>(value_type: T)
	const value_type = value_type :: DataType<Infer<T>>

	const value_write = value_type.write
	const value_read = value_type.read
	const value_size = value_type.size
	const value_write_array = value_type.write_array
	const value_read_array = value_type.read_array
	const value_size_array = value_type.size_array

	const size_fn: (value: { Infer<T> }) -> number = value_size_array
		or if type(value_size) == "number"
			then function(value)
				return SHORT + value_size * #value
			end
			else function(value)
				local total = SHORT
				for i = 1, #value do
					total += value_size(value[i])
				end
				return total
			end

	if value_write_array and value_read_array then
		return create<<{ Infer<T> }>>({
			write = value_write_array,
			read = value_read_array,
			size = size_fn,
		})
	end

	return create<<{ Infer<T> }>>({
		write = function(buff, offset, array, refs)
			const len = #array
			buffer.writeu16(buff, offset, len)
			local pos = offset + SHORT
			for i = 1, len do
				pos += value_write(buff, pos, array[i], refs)
			end
			return pos - offset
		end,
		read = function(buff, offset, refs)
			const len = buffer.readu16(buff, offset)
			const array = table.create<<any>>(len)
			local pos = offset + SHORT
			for i = 1, len do
				const length, value = value_read(buff, pos, refs)
				array[i] = value
				pos += length
			end
			return pos - offset, array
		end,
		size = size_fn,
	})
end

return array
