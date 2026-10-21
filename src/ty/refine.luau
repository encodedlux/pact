const types = require("../types")
const create = require("./create")
const constants = require("../constants")

type DataType<T = any> = types.DataType<T>
type Infer<T> = types.Infer<T>

const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME

const function refine<T>(source_type: T)
	const value_type = source_type :: DataType
	const value_write = value_type.write
	const value_read = value_type.read
	const value_size = value_type.size

	return function(refine_fn: (value: Infer<T>) -> (boolean, string?))
		return create<<Infer<T>>>({
			write = value_write,
			read = @native function(buff, offset, refs)
				const size, value = value_read(buff, offset, refs)
				local success, reason = refine_fn(value)
				if not success then
					error(
						`[{ROOT_SCOPE_NAME}]: Failed to validate value '{tostring(value)}'{if reason
							then `: {reason}`
							else ""}`
					)
				end
				return size, value
			end,
			size = value_size,
		})
	end
end

return refine
