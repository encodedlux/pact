const constants = require("../../../constants")
const create = require("../../create")
const t = require("../../../types")

type Infer<T> = t.Infer<T>
type DataType<T = any> = t.DataType<T>

const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME

const function intersect<L, R>(left_type: L & {}, right_type: R & {})
	const left_type = left_type :: DataType<{ [any]: any }>
	const right_type = right_type :: DataType<{ [any]: any }>

	const left_write = left_type.write
	const left_read = left_type.read
	const left_size = left_type.size :: any
	const left_parse = left_type.parse
	const right_write = right_type.write
	const right_read = right_type.read
	const right_size = right_type.size :: any
	const right_parse = right_type.parse

	if not left_parse or not right_parse then
		error(`[{ROOT_SCOPE_NAME}]: Both variants of an intersect must have a parse function`)
	end

	const left_fixed = typeof(left_size) == "number"
	const right_fixed = typeof(right_size) == "number"

	const size_fn = if left_fixed and right_fixed
		then left_size + right_size
		else function(value)
			const l_size = if left_fixed then left_size else left_size(value)
			const r_size = if right_fixed then right_size else right_size(value)
			return l_size + r_size
		end

	return create<<Infer<L> & Infer<R>>>({
		write = function(buff, offset, value, refs)
			const l_len = left_write(buff, offset, value, refs)
			const r_len = right_write(buff, offset + l_len, value, refs)
			return l_len + r_len
		end,
		read = function(buff, offset, refs)
			const l_len, l_val = left_read(buff, offset, refs)
			const r_len, r_val = right_read(buff, offset + l_len, refs)
			for k, v in r_val do
				if l_val[k] ~= nil then
					warn(`[{ROOT_SCOPE_NAME}]: key conflict with '{k}' in intersect, overwriting value`)
				end
				l_val[k] = v
			end
			return l_len + r_len, l_val :: any
		end,
		size = size_fn,
		parse = function(value)
			const l_ok, l_err = left_parse(value)
			if not l_ok then
				return false, `Left variant failed: {l_err}`
			end
			const r_ok, r_err = right_parse(value)
			if not r_ok then
				return false, `Right variant failed: {r_err}`
			end
			return true, nil
		end,
	})
end

return intersect
