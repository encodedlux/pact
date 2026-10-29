const types = require("../types")

type DataType<T = any> = types.DataType<T>

const function create<T>(props: {
	write: index<DataType<T>, "write">,
	read: index<DataType<T>, "read">,
	size: index<DataType<T>, "size">,
	write_array: index<DataType<T>, "write_array">?,
	read_array: index<DataType<T>, "read_array">?,
	size_array: index<DataType<T>, "size_array">?,
}): DataType<T>
	return {
		infer = (nil :: any) :: T,
		write = props.write,
		read = props.read,
		write_array = props.write_array,
		read_array = props.read_array,
		size = props.size,
	}
end

return create
