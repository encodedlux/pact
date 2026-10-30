const constants = require("../../constants")
const create = require("../create")
const types = require("../../types")

type DataType<T = any> = types.DataType<T>
type Infer<T> = types.Infer<T>

const BYTE = constants.BYTE

const function optional<T>(value_type: T)
	const value_type = value_type :: DataType

	const value_write = value_type.write
	const value_read = value_type.read
	const value_size = value_type.size :: any
	const value_parse = value_type.parse
	const fixed_size = type(value_size) == "number"

	return create<<Infer<T>?>>({
		write = function(buff, offset, value, refs)
			buffer.writeu8(buff, offset, if value == nil then 0 else 1)
			const value_length = value_write(buff, offset + BYTE, value, refs)
			return value_length + BYTE
		end,
		read = function(buff, offset, refs)
			const is_present = buffer.readu8(buff, offset)
			if is_present == 0 then
				return BYTE, nil
			end
			const value_length, value = value_read(buff, offset + BYTE, refs)
			return value_length + BYTE, value
		end,
		size = function(value)
			return if value == nil then BYTE else BYTE + if fixed_size then value_size else value_size(value)
		end,
		parse = function(value)
			if value == nil then
				return true, nil
			end
			if value_parse then
				return value_parse(value)
			end
			return true, nil
		end,
	})
end

return optional
