const create = require("../../create")
const types = require("../../../types")

type DataType<T = any> = types.DataType<T>
type InferFromFields<T> = types.InferFromFields<T>

const function struct<T>(fields: T)
	const fields = fields :: { read [string]: DataType }

	const keys: { string } = {}
	for key in fields :: any do
		keys[#keys + 1] = key
	end
	table.sort(keys)

	const count = #keys
	const writes = table.create<<any>>(count)
	const reads = table.create<<any>>(count)
	const sizes = table.create<<any>>(count)
	const parses = table.create<<any>>(count)

	for idx, key in keys do
		writes[idx] = fields[key].write
		reads[idx] = fields[key].read
		sizes[idx] = fields[key].size
		parses[idx] = fields[key].parse
	end

	local fixed_total = 0
	const variable_indices = {}
	for i, s in sizes do
		if typeof(s) == "number" then
			fixed_total += s
		else
			table.insert(variable_indices, i)
		end
	end

	const size_fn = if #variable_indices == 0
		then fixed_total
		else function(value: any)
			local total = fixed_total
			for i = 1, #variable_indices do
				const idx = variable_indices[i]
				total += sizes[idx](value[keys[idx]])
			end
			return total
		end

	return create<<InferFromFields<T>>>({
		write = function(buff, offset, value: any, refs)
			local pos = offset
			for i = 1, #writes do
				pos += writes[i](buff, pos, value[keys[i]], refs)
			end
			return pos - offset
		end,
		read = function(buff, offset, refs)
			local pos = offset
			const tbl = {}
			for i = 1, #writes do
				const length, val = reads[i](buff, pos, refs)
				tbl[keys[i]] = val
				pos += length
			end
			return tbl :: any
		end,
		size = size_fn,
		parse = function(value)
			if typeof(value) ~= "table" then
				return false, "value must be a table/struct"
			end
			for i = 1, #keys do
				const parse_fn = parses[i]
				if parse_fn then
					const ok, err = parse_fn((value :: any)[keys[i]])
					if not ok then
						return false, `field '{keys[i]}' is invalid: {err}`
					end
				end
			end
			return true, nil
		end,
	})
end

return struct
