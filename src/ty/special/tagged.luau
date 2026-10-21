const t = require("../../types")
const create = require("../create")
const constants = require("../../constants")
const struct = require("./struct")

type DataType<T = any> = t.DataType<T>
type InferFromFields<T> = t.InferFromFields<T>

const BYTE = constants.BYTE

const writeu8, readu8 = buffer.writeu8, buffer.readu8

type function tagged_type(ty: type, data_ty: type)
	data_ty:setproperty(types.singleton("type"), ty)
	return data_ty
end

type TaggedType<Type = string, Data = { [string]: any }> = tagged_type<Type, Data>

type function union_of_fields(ty: type)
	assert(ty:is("table"), "requires a table type")
	local union = nil
	for tag, v in ty:properties() do
		const fields = v.read
		if not fields then
			continue
		end
		assert(fields:is("table"), "requires a table value")
		const tagged_fields = TaggedType(tag, InferFromFields(fields))
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
	const struct_sizes = table.create<<index<DataType, "size">>>(length)
	const struct_fixeds = buffer.create(length)

	const tag_to_index = {}

	for i, tag in tags do
		tag_to_index[tag] = i
		const s = struct_map[tag]
		struct_writes[i] = s.write
		struct_reads[i] = s.read
		struct_sizes[i] = s.size
		writeu8(struct_fixeds, i - 1, typeof(s.size) == "number" and 1 or 0)
	end

	return create<<union_of_fields<T>>>({
		write = @native function(buff, offset, value: TaggedType, refs)
			const tag_index = tag_to_index[value.type]
			writeu8(buff, offset, tag_index)
			const length = struct_writes[tag_index](buff, offset + 1, value, refs)
			return BYTE + length
		end,
		read = @native function(buff, offset, refs)
			const tag_index = readu8(buff, offset)
			const length, struct_val = struct_reads[tag_index](buff, offset + 1, refs)
			struct_val.type = tags[tag_index]
			return BYTE + length, struct_val
		end,
		size = @native function(value: TaggedType)
			const tag_index = tag_to_index[value.type]
			const struct_size = struct_sizes[tag_index]
			const struct_fixed = readu8(struct_fixeds, tag_index - 1) == 1
			return BYTE + if struct_fixed then struct_size else (struct_size :: any)(value)
		end,
	})
end

return tagged
