const types = require("../../types")
const create = require("../create")
const constants = require("../../constants")

type DataType<T = any> = types.DataType<T>
type Infer<T> = types.Infer<T>

const SHORT = constants.SHORT

const writeu16, readu16 = buffer.writeu16, buffer.readu16

const function set<K>(key_type: K)
	const key_type = key_type :: DataType

	const key_write = key_type.write
	const key_read = key_type.read
	const key_size = key_type.size

	const key_fixed = typeof(key_size) == "number"

	return create<<{ [Infer<K>]: true }>>({
		write = @native function(buff, offset, value, refs)
			local current_offset = offset + SHORT
			local set_length = 0
			for k in value do
				set_length += 1
				current_offset += key_write(buff, current_offset, k, refs)
			end
			writeu16(buff, offset, set_length)
			return current_offset - offset
		end,
		read = @native function(buff, offset, refs)
			local current_offset = offset + SHORT
			const set_length = readu16(buff, offset)
			const result = {}
			for _ = 1, set_length do
				const key_length, key = key_read(buff, current_offset, refs)
				current_offset += key_length
				result[key] = true :: true
			end
			return current_offset - offset, result
		end,
		size = @native function(value)
			local total = SHORT
			for k in value do
				total += if key_fixed then key_size else (key_size :: any)(k)
			end
			return total
		end,
	})
end

return set
