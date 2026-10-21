const types = require("../types")

type DataType<T = any> = types.DataType<T>

const function create<T>(props: {
	write: index<DataType<T>, "write">,
	read: index<DataType<T>, "read">,
	size: index<DataType<T>, "size">,
}): DataType<T>
	return {
		infer = (nil :: any) :: T,
		write = props.write,
		read = props.read,
		size = props.size,
	}
end

return create
