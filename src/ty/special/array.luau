const types = require("../../types")
const create = require("../create")
const constants = require("../../constants")

type DataType<T = any> = types.DataType<T>
type Infer<T> = types.Infer<T>

const SHORT = constants.SHORT

const writeu16, readu16 = buffer.writeu16, buffer.readu16

const function array<T>(value_type: T)
	const value_type = value_type :: DataType

	const value_write = value_type.write
	const value_read = value_type.read
	const value_size = value_type.size

	const size_fn = if type(value_size) == "number"
		then @native function(value: { T }): number
			return SHORT + value_size * #value
		end
		else @native function(value: { T }): number
			local total = SHORT
			for i = 1, #value do
				total += value_size(value[i])
			end
			return total
		end

	return create<<{ Infer<T> }>>({
		write = @native function(buff, offset, value, refs)
			writeu16(buff, offset, #value)
			local current_offset = offset + SHORT
			for i = 1, #value do
				current_offset += value_write(buff, current_offset, value[i], refs)
			end
			return current_offset - offset
		end,
		read = @native function(buff, offset, refs)
			const array_length = readu16(buff, offset)
			local current_offset = offset + SHORT
			const array: { any } = table.create(array_length)
			for i = 1, array_length do
				const length, value = value_read(buff, current_offset, refs)
				current_offset += length
				array[i] = value
			end
			return current_offset - offset, array
		end,
		size = size_fn,
	})
end

return array
