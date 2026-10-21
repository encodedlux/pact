const types = require("../../types")
const create = require("../create")
const constants = require("../../constants")

type DataType<T = any> = types.DataType<T>
type Infer<T> = types.Infer<T>

const BYTE = constants.BYTE

const writeu8, readu8 = buffer.writeu8, buffer.readu8

const function optional<T>(value_type: T)
	const value_type = value_type :: DataType

	const value_write = value_type.write
	const value_read = value_type.read
	const value_size = value_type.size

	const size_fn = if type(value_size) == "number"
		then @native function(value)
			return if value == nil then BYTE else BYTE + value_size
		end
		else @native function(value)
			return if value == nil then BYTE else BYTE + value_size(value)
		end

	return create<<Infer<T>?>>({
		write = @native function(buff, offset, value, refs)
			if value == nil then
				writeu8(buff, offset, 0)
				return BYTE
			end
			const length = value_write(buff, offset + BYTE, value, refs)
			writeu8(buff, offset, BYTE)
			return length + BYTE
		end,
		read = @native function(buff, offset, refs)
			const is_present = readu8(buff, offset)
			if is_present == 0 then
				return BYTE, nil
			end
			const length, value = value_read(buff, offset + BYTE, refs)
			return length + BYTE, value
		end,
		size = size_fn,
	})
end

return optional
