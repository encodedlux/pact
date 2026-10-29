const constants = require("../../constants")
const create = require("../create")
const types = require("../../types")

type DataType<T = any> = types.DataType<T>
type Infer<T> = types.Infer<T>

const SHORT = constants.SHORT

const function map<K, V>(key_type: K, value_type: V)
	const key_type = key_type :: DataType
	const value_type = value_type :: DataType

	const key_write = key_type.write
	const key_read = key_type.read
	const key_size = key_type.size :: any
	const value_write = value_type.write
	const value_read = value_type.read
	const value_size = value_type.size :: any

	const key_fixed = typeof(key_size) == "number"
	const value_fixed = typeof(value_size) == "number"

	return create<<{ [Infer<K>]: Infer<V> }>>({
		write = function(buff, offset, value, refs)
			local pos = offset + SHORT
			local map_length = 0
			for k, v in value do
				map_length += 1
				pos += key_write(buff, pos, k, refs)
				pos += value_write(buff, pos, v, refs)
			end
			buffer.writeu16(buff, offset, map_length)
			return pos - offset
		end,
		read = function(buff, offset, refs)
			const map_length = buffer.readu16(buff, offset)
			local pos = offset + SHORT
			const result = {}
			for _ = 1, map_length do
				const key_length, key = key_read(buff, pos, refs)
				pos += key_length
				const value_length, value = value_read(buff, pos, refs)
				pos += value_length
				result[key] = value
			end
			return pos - offset, result
		end,
		size = function(value)
			local total = SHORT
			for k, v in value do
				total += if key_fixed then key_size else key_size(k)
				total += if value_fixed then value_size else value_size(v)
			end
			return total
		end,
	})
end

return map
