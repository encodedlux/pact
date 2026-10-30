const constants = require("../../../constants")
const create = require("../../create")
const t = require("../../../types")

type Infer<T> = t.Infer<T>
type DataType<T = any> = t.DataType<T>

const BYTE = constants.BYTE
const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME

const function union<L, R>(left_type: L, right_type: R)
	const left_type = left_type :: DataType
	const right_type = right_type :: DataType

	const left_write = left_type.write
	const left_read = left_type.read
	const left_size = left_type.size :: any
	const left_parse = left_type.parse
	const right_write = right_type.write
	const right_read = right_type.read
	const right_size = right_type.size :: any
	const right_parse = right_type.parse

	if not left_parse or not right_parse then
		error(`[{ROOT_SCOPE_NAME}]: Both variants of a union must have a parse function to be distinguishable`)
	end

	const left_fixed = typeof(left_size) == "number"
	const right_fixed = typeof(right_size) == "number"

	return create<<Infer<L> | Infer<R>>>({
		write = function(buff, offset, value, refs)
			if left_parse(value) then
				buffer.writeu8(buff, offset, 0)
				const len = left_write(buff, offset + BYTE, value, refs)
				return BYTE + len
			elseif right_parse(value) then
				buffer.writeu8(buff, offset, 1)
				const len = right_write(buff, offset + BYTE, value, refs)
				return BYTE + len
			end
			error(`[{ROOT_SCOPE_NAME}]: Value '{tostring(value)}' does not match any union variant`)
		end,
		read = function(buff, offset, refs)
			const tag = buffer.readu8(buff, offset)
			if tag == 0 then
				const len, val = left_read(buff, offset + BYTE, refs)
				return BYTE + len, val
			elseif tag == 1 then
				const len, val = right_read(buff, offset + BYTE, refs)
				return BYTE + len, val
			end
			error(`[{ROOT_SCOPE_NAME}]: Invalid union tag '{tag}' at offset {offset}`)
		end,
		size = function(value)
			if left_parse(value) then
				return BYTE + if left_fixed then left_size else (left_size :: any)(value)
			elseif right_parse(value) then
				return BYTE + if right_fixed then right_size else (right_size :: any)(value)
			end
			error(`[{ROOT_SCOPE_NAME}]: Value '{tostring(value)}' does not match any union variant`)
		end,
		parse = function(value)
			const l_ok, l_err = left_parse(value)
			if l_ok then
				return true, nil
			end
			const r_ok, r_err = right_parse(value)
			if r_ok then
				return true, nil
			end
			return false, `value does not match any union variant: Left: {l_err}; Right: {r_err}`
		end,
	})
end

return union
