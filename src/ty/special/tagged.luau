const constants = require("../../constants")
const create = require("../create")
const struct = require("./struct")
const t = require("../../types")

type DataType<T = any> = t.DataType<T>
type InferFromFields<T> = t.InferFromFields<T>

const BYTE = constants.BYTE

type function tagged_type(ty: type, data_ty: type)
	data_ty:setproperty(types.singleton("type"), ty)
	return data_ty
end

type AnyTaggedType = tagged_type<string, { [string]: any }>

type function union_of_fields(ty: type)
	assert(ty:is("table"), "requires a table type")
	local union = nil
	for tag, v in ty:properties() do
		const fields = v.read
		if not fields then
			continue
		end
		assert(fields:is("table"), "requires a table value")
		const tagged_fields = tagged_type(tag, InferFromFields(fields))
		union = if union then types.unionof(union, tagged_fields) else tagged_fields
	end
	return if union then union else types.singleton(nil)
end

const function tagged<T>(definition: T)
	const definition = definition :: { read [string]: { read [string]: DataType } }

	const struct_map: { [string]: DataType } = {}
	const tags: { string } = {}

	for tag, variant_def in definition do
		table.insert(tags, tag)
		struct_map[tag] = struct(variant_def)
	end
	table.sort(tags)

	const length = #tags

	const struct_writes = table.create<<index<DataType, "write">>>(length)
	const struct_reads = table.create<<index<DataType, "read">>>(length)
	const struct_sizes = table.create<<any>>(length)
	const struct_fixeds = buffer.create(length)

	const tag_to_index = {}

	for i, tag in tags do
		tag_to_index[tag] = i
		const s = struct_map[tag]
		struct_writes[i] = s.write
		struct_reads[i] = s.read
		struct_sizes[i] = s.size
		buffer.writeu8(struct_fixeds, i - 1, typeof(s.size) == "number" and 1 or 0)
	end

	return create<<union_of_fields<T>>>({
		write = function(buff, offset, value: AnyTaggedType, refs)
			const tag_index = tag_to_index[value.type]
			buffer.writeu8(buff, offset, tag_index)
			const length = struct_writes[tag_index](buff, offset + 1, value, refs)
			return BYTE + length
		end,
		read = function(buff, offset, refs)
			const tag_index = buffer.readu8(buff, offset)
			local length, struct_val = struct_reads[tag_index](buff, offset + 1, refs)
			struct_val.type = tags[tag_index]
			return length + BYTE, struct_val
		end,
		size = function(value: AnyTaggedType)
			const tag_index = tag_to_index[value.type]
			const struct_size = struct_sizes[tag_index]
			const struct_fixed = buffer.readu8(struct_fixeds, tag_index - 1) == 1
			return BYTE + if struct_fixed then struct_size else struct_size(value)
		end,
	})
end

return tagged
