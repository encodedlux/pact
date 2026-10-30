const constants = require("../../../constants")
const create = require("../../create")
const types = require("../../../types")

type DataType<T = any> = types.DataType<T>
type Infer<T> = types.Infer<T>

const SHORT = constants.SHORT

const function set<K>(key_type: K)
	const key_type = key_type :: DataType

	const key_write = key_type.write
	const key_read = key_type.read
	const key_size = key_type.size :: any
	const key_parse = key_type.parse
	const key_fixed = typeof(key_size) == "number"

	return create<<{ [Infer<K>]: true }>>({
		write = function(buff, offset, value, refs)
			local pos = offset + SHORT
			local len = 0
			for k in value do
				len += 1
				pos += key_write(buff, pos, k, refs)
			end
			buffer.writeu16(buff, offset, len)
			return pos - offset
		end,
		read = function(buff, offset, refs)
			local pos = offset + SHORT
			const len = buffer.readu16(buff, offset)
			const result = {}
			for _ = 1, len do
				const key_length, key = key_read(buff, pos, refs)
				pos += key_length
				result[key] = true :: true
			end
			return pos - offset, result
		end,
		size = function(value)
			local total = SHORT
			for k in value do
				total += if key_fixed then key_size else key_size(k)
			end
			return total
		end,
		parse = function(value)
			if typeof(value) ~= "table" then
				return false, "value must be a table/set"
			end
			if key_parse then
				for k in value do
					const ok, err = key_parse(k)
					if not ok then
						return false, `set element '{tostring(k)}' is invalid: {err}`
					end
				end
			end
			return true, nil
		end,
	})
end

return set
