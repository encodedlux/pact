const types = require("../../types")
const create = require("../create")

type DataType<T = any> = types.DataType<T>
type InferFromFields<T> = types.InferFromFields<T>

const function struct<T>(fields: T)
	const fields = fields :: { read [string]: DataType }

	const keys: { string } = {}
	const value_writes: { index<DataType<InferFromFields<T>>, "write"> } = {}
	const value_reads: { index<DataType<InferFromFields<T>>, "read"> } = {}
	const value_sizes: { index<DataType<InferFromFields<T>>, "size"> } = {}

	for key in fields :: any do
		keys[#keys + 1] = key
	end
	table.sort(keys)

	for idx, key in keys do
		value_writes[idx] = fields[key].write
		value_reads[idx] = fields[key].read
		value_sizes[idx] = fields[key].size
	end

	local fixed_total = 0
	const variable_indices = {}
	for i, s in value_sizes do
		if type(s) == "number" then
			fixed_total += s
		else
			table.insert(variable_indices, i)
		end
	end

	const size = if #variable_indices == 0
		then fixed_total
		else @native function(value)
			local total = fixed_total
			for i = 1, #variable_indices do
				const idx = variable_indices[i]
				total += (value_sizes[idx] :: any)(value[keys[idx]])
			end
			return total
		end

	return create<<InferFromFields<T>>>({
		write = @native function(buff, offset, value, refs)
			local current_offset = offset
			for i = 1, #value_writes do
				current_offset += value_writes[i](buff, current_offset, (value :: any)[keys[i]], refs)
			end
			return current_offset - offset
		end,
		read = @native function(buff, offset, refs)
			local current_offset = offset
			const data = {}
			for i = 1, #value_writes do
				const length, value = value_reads[i](buff, current_offset, refs)
				current_offset += length
				data[keys[i]] = value
			end
			return current_offset - offset, data :: any
		end,
		size = size,
	})
end

return struct
