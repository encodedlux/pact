const types = require("../../types")
const create = require("../create")
const constants = require("../../constants")

type DataType<T = any> = types.DataType<T>
type Infer<T> = types.Infer<T>

const SHORT = constants.SHORT

const writeu16, readu16 = buffer.writeu16, buffer.readu16

const function map<K, V>(key_type: K, value_type: V)
	const key_type = key_type :: DataType
	const value_type = value_type :: DataType

	const key_write = key_type.write
	const key_read = key_type.read
	const key_size = key_type.size
	const value_write = value_type.write
	const value_read = value_type.read
	const value_size = value_type.size

	const key_fixed = typeof(key_size) == "number"
	const value_fixed = typeof(value_size) == "number"

	return create<<{ [Infer<K>]: Infer<V> }>>({
		write = @native function(buff, offset, value, refs)
			local current_offset = offset + SHORT
			local map_length = 0
			for k, v in value do
				map_length += 1
				current_offset += key_write(buff, current_offset, k, refs)
				current_offset += value_write(buff, current_offset, v, refs)
			end
			writeu16(buff, offset, map_length)
			return current_offset - offset
		end,
		read = @native function(buff, offset, refs)
			local current_offset = offset + SHORT
			const map_length = readu16(buff, offset)
			const result = {}
			for _ = 1, map_length do
				const key_length, key = key_read(buff, current_offset, refs)
				current_offset += key_length
				const val_length, value = value_read(buff, current_offset, refs)
				current_offset += val_length
				result[key] = value
			end
			return current_offset - offset, result
		end,
		size = @native function(value)
			local total = SHORT
			for k, v in value do
				total += if key_fixed then key_size else (key_size :: any)(k)
				total += if value_fixed then value_size else (value_size :: any)(v)
			end
			return total
		end,
	})
end

return map
