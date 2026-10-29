const constants = require("../../constants")
const create = require("../create")
const types = require("../../types")

type DataType<T> = types.DataType<T>

const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME

const function literal<T>(literal_value: T): DataType<T>
	return create<<T>>({
		write = function(buff, offset, value)
			assert(
				value == literal_value,
				`[{ROOT_SCOPE_NAME}]: Value "{value}" does not match literal value "{literal_value}"`
			)
			return 0
		end,
		read = function(buff, offset)
			return 0, literal_value
		end,
		size = 0,
	})
end

return literal
