--!native
--!optimize 2

-- [ Types ]

export type DataType<T = any> = {
	read type: string | { string },
	read infer: T,
	read write: (buff: buffer, offset: number, value: T, refs: { [any]: any }) -> number,
	read read: (buff: buffer, offset: number, refs: { [any]: any }) -> (number, T),
	read size: number | (value: T) -> number,
}

export type Infer<T> = index<T, "infer">

export type function infer_from_fields(fields: type)
	assert(fields:is("table"), "expected a table")
	local result = types.newtable()
	for key, value in fields:properties() do
		if value.read then
			result:setproperty(key, Infer(value.read))
		end
	end
	return result
end

export type function infer_from_tuple(tuple_ty: type, i: type)
	assert(tuple_ty:is("function"), "expected a t.tuple")
	const returns = tuple_ty:returns()
	if i == types.singleton("#") then
		return types.singleton(tostring(#(returns.head or {})))
	end
	const pos = assert(i and i:is("singleton") and tonumber(i:value()), "expected a pos selection")
	const arg_ty = (returns.head and returns.head[pos :: any]) :: type
	assert(arg_ty, "pos selection is out of bounds")
	return Infer(arg_ty)
end

type function enum_auto_complete(ty: type)
	if ty.tag == "union" then
		for _, v in ty:components() do
			if v.tag == "singleton" then
				ty = v
				break
			end
		end
	end
	const value = ty:value()
	const values = string.split(value :: string, ", ")
	if #values < 2 then
		error(`Enum values have to be separated by ", "`)
	end
	return types.unionof(ty, types.singleton(`{value}, `))
end

type function enum_infer(ty: type): type
	assert(ty:is("singleton"), "Enum must be a singleton type")
	const values = string.split(ty:value() :: string, ", ")
	local union = nil
	for i = 1, #values do
		const value_ty = types.singleton(values[i])
		union = if union then types.unionof(union, value_ty) else value_ty
	end
	return if union then union else types.singleton(nil)
end

type function tagged_fields(ty: type, fields_ty: type)
	const result = types.copy(fields_ty)
	result:setproperty(types.singleton("type"), ty)
	return result
end

type AnyTaggedFields = tagged_fields<string, { [string]: any }>

type function tagged_infer(ty: type)
	assert(ty:is("table"), "requires a table type")
	local union = nil
	for tag, v in ty:properties() do
		const fields = v.read
		if not fields then
			continue
		end
		assert(fields:is("table"), "requires a table value")
		const val = tagged_fields(tag, infer_from_fields(fields))
		union = if union then types.unionof(union, val) else val
	end
	return if union then union else types.singleton(nil)
end

type Union =
	(<A, B>(A, B) -> DataType<Infer<A> | Infer<B>>)
	& (<A, B, C>(A, B, C) -> DataType<Infer<A> | Infer<B> | Infer<C>>)
	& (<A, B, C, D>(A, B, C, D) -> DataType<Infer<A> | Infer<B> | Infer<C> | Infer<D>>)
	& (<A, B, C, D, E>(A, B, C, D, E) -> DataType<Infer<A> | Infer<B> | Infer<C> | Infer<D> | Infer<E>>)

type Intersect =
	(<A, B>(A & {}, B & {}) -> DataType<Infer<A> & Infer<B>>)
	& (<A, B, C>(A & {}, B & {}, C & {}) -> DataType<Infer<A> & Infer<B> & Infer<C>>)
	& (<A, B, C, D>(A & {}, B & {}, C & {}, D & {}) -> DataType<Infer<A> & Infer<B> & Infer<C> & Infer<D>>)
	& (<A, B, C, D, E>(A & {}, B & {}, C & {}, D & {}, E & {}) -> DataType<Infer<A> & Infer<B> & Infer<C> & Infer<D> & Infer<E>>)

type function tuple(max_args: type)
	const count = max_args:is("singleton") and tonumber(max_args:value())
	assert(count and count >= 2, "expected a max argument count >= 2")
	local overloads = nil
	for n = 2, count :: number do
		const args: { type } = {}
		for i = 1, n do
			args[i] = types.generic("T" .. i)
		end
		const get_args = types.newfunction({}, { head = args })
		const tuple_fn = types.newfunction({ head = args }, { head = { get_args } }, args)
		overloads = if overloads then types.intersectionof(overloads, tuple_fn) else tuple_fn
	end
	return overloads :: type
end

const Players = game:GetService("Players")

const null_ref = newproxy()

-- [ Core ]

const function create<T>(props: {
	type: index<DataType<T>, "type">,
	write: index<DataType<T>, "write">,
	read: index<DataType<T>, "read">,
	size: index<DataType<T>, "size">,
}): DataType<T>
	return table.freeze({
		type = props.type,
		write = props.write,
		read = props.read,
		size = props.size,
	})
end

const function refine<T>(value_type: T)
	const value_type = value_type :: DataType
	const value_read = value_type.read

	return function(refine_fn: (value: Infer<T>) -> (boolean, string?))
		return create<<Infer<T>>>({
			type = value_type.type,
			write = value_type.write,
			read = function(buff, offset, refs)
				const size, value = value_read(buff, offset, refs)
				local success, reason = refine_fn(value)
				if not success then
					error(`Failed to validate value '{tostring(value)}'{if reason then `: {reason}` else ""}`)
				end
				return size, value
			end,
			size = value_type.size,
		})
	end
end

const function push_ref(refs: { [any]: any }, value: any)
	table.insert(refs, if value == nil then null_ref else value)
end

const function next_ref(refs: { [any]: any })
	const cursor = (refs.cursor or 0) + 1
	const val = refs[cursor]
	refs.cursor = cursor
	return if val == null_ref then nil else val
end

const function get_types(value_type: DataType): { string }
	const value_typeof = value_type.type
	return if type(value_typeof) == "table" then table.clone(value_typeof) else { value_typeof }
end

-- [ Numbers ]

const u8 = create<<number>>({
	type = "number",
	write = function(buff, offset, value)
		buffer.writeu8(buff, offset, value)
		return 1
	end,
	read = function(buff, offset)
		return 1, buffer.readu8(buff, offset)
	end,
	size = 1,
})

const u16 = create<<number>>({
	type = "number",
	write = function(buff, offset, value)
		buffer.writeu16(buff, offset, value)
		return 2
	end,
	read = function(buff, offset)
		return 2, buffer.readu16(buff, offset)
	end,
	size = 2,
})

const u32 = create<<number>>({
	type = "number",
	write = function(buff, offset, value)
		buffer.writeu32(buff, offset, value)
		return 4
	end,
	read = function(buff, offset)
		return 4, buffer.readu32(buff, offset)
	end,
	size = 4,
})

const i8 = create<<number>>({
	type = "number",
	write = function(buff, offset, value)
		buffer.writei8(buff, offset, value)
		return 1
	end,
	read = function(buff, offset)
		return 1, buffer.readi8(buff, offset)
	end,
	size = 1,
})

const i16 = create<<number>>({
	type = "number",
	write = function(buff, offset, value)
		buffer.writei16(buff, offset, value)
		return 2
	end,
	read = function(buff, offset)
		return 2, buffer.readi16(buff, offset)
	end,
	size = 2,
})

const i32 = create<<number>>({
	type = "number",
	write = function(buff, offset, value)
		buffer.writei32(buff, offset, value)
		return 4
	end,
	read = function(buff, offset)
		return 4, buffer.readi32(buff, offset)
	end,
	size = 4,
})

const f16 = create<<number>>({
	type = "number",
	write = function(buff, offset, value)
		if value > 65504 then
			buffer.writeu16(buff, offset, 0b0_11111_0000000000)
		elseif value < -65504 then
			buffer.writeu16(buff, offset, 0b1_11111_0000000000)
		elseif value ~= value then
			buffer.writeu16(buff, offset, 0b0_11111_0000000001)
		elseif value == 0 then
			buffer.writeu16(buff, offset, 0)
		else
			const absValue = math.abs(value)
			const interval = math.ldexp(1, math.floor(math.log(absValue, 2)) - 10)
			const rounded_value = (absValue // interval) * interval
			local fraction, exponent = math.frexp(rounded_value)
			exponent += 14
			const mantissa = math.round(if exponent <= 0 then fraction * 0x400 / math.ldexp(1, math.abs(exponent)) else fraction * 0x800) % 0x400

			const result = mantissa + math.max(exponent, 0) * 0x400 + if value < 0 then 0x8000 else 0

			buffer.writeu16(buff, offset, result)
		end
		return 2
	end,
	read = function(buff, offset)
		const encoded = buffer.readu16(buff, offset)
		const mantissa_exponent = encoded % 0x8000

		if mantissa_exponent == 0b0_11111_0000000000 then
			return 2, if encoded // 0x8000 == 1 then -math.huge else math.huge
		elseif mantissa_exponent > 0b0_11111_0000000000 then
			return 2, 0 / 0
		elseif mantissa_exponent == 0 then
			return 2, 0
		else
			const mantissa = mantissa_exponent % 0x400
			const exponent = mantissa_exponent // 0x400
			local fraction
			if exponent == 0 then
				fraction = mantissa / 0x400
			else
				fraction = mantissa / 0x800 + 0.5
			end
			const result = math.ldexp(fraction, exponent - 14)
			return 2, if encoded // 0x8000 == 1 then -result else result
		end
	end,
	size = 2,
})

const f32 = create<<number>>({
	type = "number",
	write = function(buff, offset, value)
		buffer.writef32(buff, offset, value)
		return 4
	end,
	read = function(buff, offset)
		return 4, buffer.readf32(buff, offset)
	end,
	size = 4,
})

const f64 = create<<number>>({
	type = "number",
	write = function(buff, offset, value)
		buffer.writef64(buff, offset, value)
		return 8
	end,
	read = function(buff, offset)
		return 8, buffer.readf64(buff, offset)
	end,
	size = 8,
})

-- [ Primitives ]

const boolean = create<<boolean>>({
	type = "boolean",
	write = function(buff, offset, value)
		buffer.writeu8(buff, offset, if value then 1 else 0)
		return 1
	end,
	read = function(buff, offset)
		return 1, buffer.readu8(buff, offset) == 1
	end,
	size = 1,
})

const string_ty = create<<string>>({
	type = "string",
	write = function(buff, offset, value)
		const len = #value
		buffer.writeu16(buff, offset, len)
		buffer.writestring(buff, offset + 2, value, len)
		return 2 + len
	end,
	read = function(buff, offset)
		const len = buffer.readu16(buff, offset)
		if offset + 2 + len > buffer.len(buff) then
			return 2, ""
		end
		return 2 + len, buffer.readstring(buff, offset + 2, len)
	end,
	size = function(value)
		return 2 + #value
	end,
})

const buffer_ty = create<<buffer>>({
	type = "buffer",
	write = function(buff, offset, value)
		const len = buffer.len(value)
		buffer.writeu16(buff, offset, len)
		buffer.copy(buff, offset + 2, value, 0, len)
		return 2 + len
	end,
	read = function(buff, offset)
		const len = buffer.readu16(buff, offset)
		if offset + 2 + len > buffer.len(buff) then
			return 2, buffer.create(0)
		end
		const new_buff = buffer.create(len)
		buffer.copy(new_buff, 0, buff, offset + 2, len)
		return 2 + len, new_buff
	end,
	size = function(value: buffer)
		return 2 + buffer.len(value)
	end,
})

const unknown = create<<any>>({
	type = "unknown",
	write = function(buff, offset, value, refs)
		push_ref(refs, value)
		return 0
	end,
	read = function(buff, offset, refs)
		return 0, next_ref(refs)
	end,
	size = 0,
})

const none = create<<nil>>({
	type = "nil",
	write = function()
		return 0
	end,
	read = function()
		return 0, nil
	end,
	size = 0,
})

const vec = create<<vector>>({
	type = "vector",
	write = function(buff, offset, value)
		buffer.writef32(buff, offset, value.x)
		buffer.writef32(buff, offset + 4, value.y)
		buffer.writef32(buff, offset + 8, value.z)
		return 12
	end,
	read = function(buff, offset)
		return 12, vector.create(buffer.readf32(buff, offset), buffer.readf32(buff, offset + 4), buffer.readf32(buff, offset + 8))
	end,
	size = 12,
})

-- [ Roblox Types ]

const vec2 = create<<Vector2>>({
	type = "Vector2",
	write = function(buff, offset, value)
		buffer.writef32(buff, offset, value.X)
		buffer.writef32(buff, offset + 4, value.Y)
		return 8
	end,
	read = function(buff, offset)
		return 8, Vector2.new(buffer.readf32(buff, offset), buffer.readf32(buff, offset + 4))
	end,
	size = 8,
})

const vec3 = create<<Vector3>>({
	type = "Vector3",
	write = function(buff, offset, value)
		buffer.writef32(buff, offset, value.X)
		buffer.writef32(buff, offset + 4, value.Y)
		buffer.writef32(buff, offset + 8, value.Z)
		return 12
	end,
	read = function(buff, offset)
		return 12, Vector3.new(buffer.readf32(buff, offset), buffer.readf32(buff, offset + 4), buffer.readf32(buff, offset + 8))
	end,
	size = 12,
})

const cframe = create<<CFrame>>({
	type = "CFrame",
	write = function(buff, offset, value: CFrame)
		buffer.writef32(buff, offset, value.X)
		buffer.writef32(buff, offset + 4, value.Y)
		buffer.writef32(buff, offset + 8, value.Z)
		const axis, angle = value:ToAxisAngle()
		const r = axis * angle
		buffer.writef32(buff, offset + 12, r.X)
		buffer.writef32(buff, offset + 16, r.Y)
		buffer.writef32(buff, offset + 20, r.Z)
		return 24
	end,
	read = function(buff, offset)
		const x = buffer.readf32(buff, offset)
		const y = buffer.readf32(buff, offset + 4)
		const z = buffer.readf32(buff, offset + 8)
		const rx = buffer.readf32(buff, offset + 12)
		const ry = buffer.readf32(buff, offset + 16)
		const rz = buffer.readf32(buff, offset + 20)
		const angle = math.sqrt((rx * rx) + (ry * ry) + (rz * rz))
		if angle == 0 then
			return 24, CFrame.new(x, y, z)
		end
		const inv = (1 / angle)
		const half = angle * 0.5
		const sin = math.sin(half)
		return 24, CFrame.new(x, y, z, (rx * inv) * sin, (ry * inv) * sin, (rz * inv) * sin, math.cos(half))
	end,
	size = 24,
})

const color3 = create<<Color3>>({
	type = "Color3",
	write = function(buff, offset, value)
		buffer.writeu8(buff, offset, math.round(value.R * 255))
		buffer.writeu8(buff, offset + 1, math.round(value.G * 255))
		buffer.writeu8(buff, offset + 2, math.round(value.B * 255))
		return 3
	end,
	read = function(buff, offset)
		return 3, Color3.fromRGB(buffer.readu8(buff, offset), buffer.readu8(buff, offset + 1), buffer.readu8(buff, offset + 2))
	end,
	size = 3,
})

const player = create<<Player>>({
	type = "Instance",
	write = function(buff, offset, p)
		buffer.writef64(buff, offset, p.UserId)
		return 8
	end,
	read = function(buff, offset)
		return 8, Players:GetPlayerByUserId(buffer.readf64(buff, offset)) :: Player
	end,
	size = 8,
})

const instance = create<<Instance>>({
	type = "Instance",
	write = function(buff, offset, value, refs)
		push_ref(refs, value)
		return 0
	end,
	read = function(buff, offset, refs)
		const inst: Instance = next_ref(refs)
		assert(typeof(inst) == "Instance", "Expected Instance, got " .. typeof(inst))
		return 0, inst
	end,
	size = 0,
})

-- [ Optional ]

const function optional<T>(value_type: T)
	const value_type = value_type :: DataType

	const value_types = get_types(value_type)
	const value_write = value_type.write
	const value_read = value_type.read
	const value_size = value_type.size :: any
	const static_size = type(value_size) == "number"

	value_types[#value_types + 1] = "nil"

	return create<<Infer<T>?>>({
		type = value_types,
		write = function(buff, offset, value, refs)
			if value == nil then
				buffer.writeu8(buff, offset, 0)
				return 1
			end
			buffer.writeu8(buff, offset, 1)
			const value_length = value_write(buff, offset + 1, value, refs)
			return 1 + value_length
		end,
		read = function(buff, offset, refs)
			const is_present = buffer.readu8(buff, offset)
			if is_present == 0 then
				return 1, nil
			end
			const value_length, value = value_read(buff, offset + 1, refs)
			return value_length + 1, value
		end,
		size = function(value)
			return if value == nil then 1 else 1 + if static_size then value_size else value_size(value)
		end,
	})
end

-- [ Literals ]

const function literal<T>(literal_value: T): DataType<T>
	return create<<T>>({
		type = typeof(literal_value),
		write = function(buff, offset, value)
			assert(value == literal_value, `Value "{value}" does not match literal value "{literal_value}"`)
			return 0
		end,
		read = function(buff, offset)
			return 0, literal_value
		end,
		size = 0,
	})
end

const function enum<T>(comma_string: T | "" | enum_auto_complete<T>)
	const values = string.split(comma_string, ", ")
	const value_map: { [string]: number } = {}
	for i = 1, #values do
		value_map[values[i]] = i
	end

	return create<<enum_infer<T>>>({
		type = "string",
		write = function(buff, offset, value)
			buffer.writeu8(buff, offset, value_map[value])
			return 1
		end,
		read = function(buff, offset)
			return 1, values[buffer.readu8(buff, offset)] :: any
		end,
		size = 1,
	})
end

-- [ Structures ]

const function array<T>(value_type: T)
	const value_type = value_type :: DataType<Infer<T>>

	const value_write = value_type.write
	const value_read = value_type.read
	const value_size = value_type.size

	const size_fn: (value: { Infer<T> }) -> number = if type(value_size) == "number"
		then function(value)
			return 2 + value_size * #value
		end
		else function(value)
			local total = 2
			for i = 1, #value do
				total += value_size(value[i])
			end
			return total
		end

	return create<<{ Infer<T> }>>({
		type = "table",
		write = function(buff, offset, array, refs)
			const len = #array
			buffer.writeu16(buff, offset, len)
			local pos = offset + 2
			for i = 1, len do
				pos += value_write(buff, pos, array[i], refs)
			end
			return pos - offset
		end,
		read = function(buff, offset, refs)
			const len = buffer.readu16(buff, offset)
			const array = table.create<<any>>(len)
			local pos = offset + 2
			for i = 1, len do
				const length, value = value_read(buff, pos, refs)
				array[i] = value
				pos += length
			end
			return pos - offset, array
		end,
		size = size_fn,
	})
end

const function set<K>(key_type: K)
	const key_type = key_type :: DataType

	const key_write = key_type.write
	const key_read = key_type.read
	const key_size = key_type.size :: any
	const key_static = type(key_size) == "number"

	return create<<{ [Infer<K>]: true }>>({
		type = "table",
		write = function(buff, offset, value, refs)
			local pos = offset + 2
			local len = 0
			for k in value do
				len += 1
				pos += key_write(buff, pos, k, refs)
			end
			buffer.writeu16(buff, offset, len)
			return pos - offset
		end,
		read = function(buff, offset, refs)
			local pos = offset + 2
			const len = buffer.readu16(buff, offset)
			const result = {}
			for _ = 1, len do
				const key_length, key = key_read(buff, pos, refs)
				pos += key_length
				result[key] = true :: true
			end
			return pos - offset, result
		end,
		size = function(value)
			local total = 2
			for k in value do
				total += if key_static then key_size else key_size(k)
			end
			return total
		end,
	})
end

const function map<K, V>(key_type: K, value_type: V)
	const key_type = key_type :: DataType
	const value_type = value_type :: DataType

	const key_write = key_type.write
	const key_read = key_type.read
	const key_size = key_type.size :: any
	const value_write = value_type.write
	const value_read = value_type.read
	const value_size = value_type.size :: any

	const key_static = type(key_size) == "number"
	const value_static = type(value_size) == "number"

	const size_fn = if key_static and value_static
		then function(value)
			local count = 0
			for _ in value do
				count += 1
			end
			return count * (key_size + value_size) + 2
		end
		else function(value)
			local total = 2
			for k, v in value do
				total += if key_static then key_size else key_size(k)
				total += if value_static then value_size else value_size(v)
			end
			return total
		end

	return create<<{ [Infer<K>]: Infer<V> }>>({
		type = "table",
		write = function(buff, offset, value, refs)
			local pos = offset + 2
			local map_length = 0
			for k, v in value do
				map_length += 1
				pos += key_write(buff, pos, k, refs)
				pos += value_write(buff, pos, v, refs)
			end
			buffer.writeu16(buff, offset, map_length)
			return pos - offset
		end,
		read = function(buff, offset, refs)
			const map_length = buffer.readu16(buff, offset)
			local pos = offset + 2
			const result = {}
			for _ = 1, map_length do
				const key_length, key = key_read(buff, pos, refs)
				pos += key_length
				const value_length, value = value_read(buff, pos, refs)
				pos += value_length
				result[key] = value
			end
			return pos - offset, result
		end,
		size = size_fn,
	})
end

const function build_struct_write(keys: { string }, fields: { [string]: DataType }): index<DataType, "write">
	const count = #keys
	if count == 0 then
		return function()
			return 0
		end
	elseif count == 1 then
		const k = keys[1]
		const write = fields[k].write
		return function(buff, offset, value, refs)
			return write(buff, offset, value[k], refs)
		end
	elseif count == 2 then
		const k1, k2 = keys[1], keys[2]
		const write1, write2 = fields[k1].write, fields[k2].write
		return function(buff, offset, value, refs)
			const len1 = write1(buff, offset, value[k1], refs)
			return len1 + write2(buff, offset + len1, value[k2], refs)
		end
	elseif count == 3 then
		const k1, k2, k3 = keys[1], keys[2], keys[3]
		const write1, write2, write3 = fields[k1].write, fields[k2].write, fields[k3].write
		return function(buff, offset, value, refs)
			local pos = offset
			pos += write1(buff, pos, value[k1], refs)
			pos += write2(buff, pos, value[k2], refs)
			pos += write3(buff, pos, value[k3], refs)
			return pos - offset
		end
	elseif count == 4 then
		const k1, k2, k3, k4 = keys[1], keys[2], keys[3], keys[4]
		const write1, write2, write3, write4 = fields[k1].write, fields[k2].write, fields[k3].write, fields[k4].write
		return function(buff, offset, value, refs)
			local pos = offset
			pos += write1(buff, pos, value[k1], refs)
			pos += write2(buff, pos, value[k2], refs)
			pos += write3(buff, pos, value[k3], refs)
			pos += write4(buff, pos, value[k4], refs)
			return pos - offset
		end
	end
	const k1, k2, k3, k4, k5 = keys[1], keys[2], keys[3], keys[4], keys[5]
	const write1, write2, write3, write4, write5 = fields[k1].write, fields[k2].write, fields[k3].write, fields[k4].write, fields[k5].write
	if count == 5 then
		return function(buff, offset, value, refs)
			local pos = offset
			pos += write1(buff, pos, value[k1], refs)
			pos += write2(buff, pos, value[k2], refs)
			pos += write3(buff, pos, value[k3], refs)
			pos += write4(buff, pos, value[k4], refs)
			pos += write5(buff, pos, value[k5], refs)
			return pos - offset
		end
	end
	const writes = table.create<<index<DataType, "write">>>(count)
	for idx, key in keys do
		writes[idx] = fields[key].write
	end
	return function(buff, offset, value, refs)
		local pos = offset
		pos += write1(buff, pos, value[k1], refs)
		pos += write2(buff, pos, value[k2], refs)
		pos += write3(buff, pos, value[k3], refs)
		pos += write4(buff, pos, value[k4], refs)
		pos += write5(buff, pos, value[k5], refs)
		for i = 6, count do
			pos += writes[i](buff, pos, value[keys[i]], refs)
		end
		return pos - offset
	end
end

const function build_struct_read(keys: { string }, fields: { [string]: DataType }): index<DataType, "read">
	const count = #keys
	if count == 0 then
		return function()
			return 0, {}
		end
	elseif count == 1 then
		const k = keys[1]
		const read = fields[k].read
		return function(buff, offset, refs)
			const len, val = read(buff, offset, refs)
			return len, { [k] = val }
		end
	elseif count == 2 then
		const k1, k2 = keys[1], keys[2]
		const read1, read2 = fields[k1].read, fields[k2].read
		return function(buff, offset, refs)
			const len1, val1 = read1(buff, offset, refs)
			const len2, val2 = read2(buff, offset + len1, refs)
			return len1 + len2, {
				[k1] = val1,
				[k2] = val2,
			}
		end
	elseif count == 3 then
		const k1, k2, k3 = keys[1], keys[2], keys[3]
		const read1, read2, read3 = fields[k1].read, fields[k2].read, fields[k3].read
		return function(buff, offset, refs)
			local pos = offset
			const len1, val1 = read1(buff, pos, refs)
			pos += len1
			const len2, val2 = read2(buff, pos, refs)
			pos += len2
			const len3, val3 = read3(buff, pos, refs)
			pos += len3
			return pos - offset, {
				[k1] = val1,
				[k2] = val2,
				[k3] = val3,
			}
		end
	elseif count == 4 then
		const k1, k2, k3, k4 = keys[1], keys[2], keys[3], keys[4]
		const read1, read2, read3, read4 = fields[k1].read, fields[k2].read, fields[k3].read, fields[k4].read
		return function(buff, offset, refs)
			local pos = offset
			const len1, val1 = read1(buff, pos, refs)
			pos += len1
			const len2, val2 = read2(buff, pos, refs)
			pos += len2
			const len3, val3 = read3(buff, pos, refs)
			pos += len3
			const len4, val4 = read4(buff, pos, refs)
			pos += len4
			return pos - offset, {
				[k1] = val1,
				[k2] = val2,
				[k3] = val3,
				[k4] = val4,
			}
		end
	end
	const k1, k2, k3, k4, k5 = keys[1], keys[2], keys[3], keys[4], keys[5]
	const read1, read2, read3, read4, read5 = fields[k1].read, fields[k2].read, fields[k3].read, fields[k4].read, fields[k5].read
	if count == 5 then
		return function(buff, offset, refs)
			local pos = offset
			const len1, val1 = read1(buff, pos, refs)
			pos += len1
			const len2, val2 = read2(buff, pos, refs)
			pos += len2
			const len3, val3 = read3(buff, pos, refs)
			pos += len3
			const len4, val4 = read4(buff, pos, refs)
			pos += len4
			const len5, val5 = read5(buff, pos, refs)
			pos += len5
			return pos - offset, {
				[k1] = val1,
				[k2] = val2,
				[k3] = val3,
				[k4] = val4,
				[k5] = val5,
			}
		end
	end
	const reads = table.create<<index<DataType, "read">>>(count)
	for idx, key in keys do
		reads[idx] = fields[key].read
	end
	return function(buff, offset, refs)
		local pos = offset
		const len1, val1 = read1(buff, pos, refs)
		pos += len1
		const len2, val2 = read2(buff, pos, refs)
		pos += len2
		const len3, val3 = read3(buff, pos, refs)
		pos += len3
		const len4, val4 = read4(buff, pos, refs)
		pos += len4
		const len5, val5 = read5(buff, pos, refs)
		pos += len5
		const tbl = {
			[k1] = val1,
			[k2] = val2,
			[k3] = val3,
			[k4] = val4,
			[k5] = val5,
		}
		for i = 6, count do
			const length, val = reads[i](buff, pos, refs)
			tbl[keys[i]] = val
			pos += length
		end
		return pos - offset, tbl
	end
end

const function build_struct_size(keys: { string }, fields: { [string]: DataType }): index<DataType, "size">
	local static_total = 0
	const dyn_keys: { string } = {}
	const dyn_sizes: { (any) -> number } = {}

	for _, key in keys do
		const size = fields[key].size
		if type(size) == "number" then
			static_total += size
		else
			table.insert(dyn_keys, key)
			table.insert(dyn_sizes, size :: any)
		end
	end

	const dyn_count = #dyn_keys
	if dyn_count == 0 then
		return static_total
	elseif dyn_count == 1 then
		const k1, s1 = dyn_keys[1], dyn_sizes[1]
		return function(value)
			return static_total + s1(value[k1])
		end
	elseif dyn_count == 2 then
		const k1, k2 = dyn_keys[1], dyn_keys[2]
		const s1, s2 = dyn_sizes[1], dyn_sizes[2]
		return function(value)
			return static_total + s1(value[k1]) + s2(value[k2])
		end
	elseif dyn_count == 3 then
		const k1, k2, k3 = dyn_keys[1], dyn_keys[2], dyn_keys[3]
		const s1, s2, s3 = dyn_sizes[1], dyn_sizes[2], dyn_sizes[3]
		return function(value)
			return static_total + s1(value[k1]) + s2(value[k2]) + s3(value[k3])
		end
	elseif dyn_count == 4 then
		const k1, k2, k3, k4 = dyn_keys[1], dyn_keys[2], dyn_keys[3], dyn_keys[4]
		const s1, s2, s3, s4 = dyn_sizes[1], dyn_sizes[2], dyn_sizes[3], dyn_sizes[4]
		return function(value)
			return static_total + s1(value[k1]) + s2(value[k2]) + s3(value[k3]) + s4(value[k4])
		end
	elseif dyn_count == 5 then
		const k1, k2, k3, k4, k5 = dyn_keys[1], dyn_keys[2], dyn_keys[3], dyn_keys[4], dyn_keys[5]
		const s1, s2, s3, s4, s5 = dyn_sizes[1], dyn_sizes[2], dyn_sizes[3], dyn_sizes[4], dyn_sizes[5]
		return function(value)
			return static_total + s1(value[k1]) + s2(value[k2]) + s3(value[k3]) + s4(value[k4]) + s5(value[k5])
		end
	end
	return function(value)
		local total = static_total
		for i = 1, dyn_count do
			total += dyn_sizes[i](value[dyn_keys[i]])
		end
		return total
	end
end

const function struct<T>(fields: T & {})
	const fields = fields :: { [string]: DataType }

	const keys: { string } = {}
	for key in fields :: any do
		assert(type(key) == "string", `expected string key, got {key} ({typeof(key)})`)
		keys[#keys + 1] = key
	end
	table.sort(keys)

	return create<<infer_from_fields<T>>>({
		type = "table",
		write = build_struct_write(keys, fields),
		read = build_struct_read(keys, fields),
		size = build_struct_size(keys, fields),
	})
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
	const struct_static_sizes = buffer.create(length)

	const tag_to_index = {}

	for i, tag in tags do
		tag_to_index[tag] = i
		const s = struct_map[tag]
		struct_writes[i] = s.write
		struct_reads[i] = s.read
		struct_sizes[i] = s.size
		buffer.writeu8(struct_static_sizes, i - 1, type(s.size) == "number" and 1 or 0)
	end

	return create<<tagged_infer<T>>>({
		type = "table",
		write = function(buff, offset, value: AnyTaggedFields, refs)
			const tag_index = tag_to_index[value.type]
			buffer.writeu8(buff, offset, tag_index)
			const length = struct_writes[tag_index](buff, offset + 1, value, refs)
			return 1 + length
		end,
		read = function(buff, offset, refs)
			const tag_index = buffer.readu8(buff, offset)
			local length, struct_val = struct_reads[tag_index](buff, offset + 1, refs)
			struct_val.type = tags[tag_index]
			return 1 + length, struct_val
		end,
		size = function(value: AnyTaggedFields)
			const tag_index = tag_to_index[value.type]
			const struct_size = struct_sizes[tag_index]
			const struct_static = buffer.readu8(struct_static_sizes, tag_index - 1) == 1
			return 1 + if struct_static then struct_size else struct_size(value)
		end,
	})
end

-- [ Combinators ]

const union: Union = function(...)
	const variants = { ... } :: { DataType }
	const count = #variants
	assert(count >= 2, "union requires at least 2 types")

	const writes = table.create<<index<DataType, "write">>>(count)
	const reads = table.create<<index<DataType, "read">>>(count)
	const static_sizes = table.create(count, -1)
	const size_fns = table.create<<((any) -> number) | false>>(count, false)

	const lookup: { [string]: number } = {}
	const merged: { string } = {}

	for i, variant in variants do
		for _, t in get_types(variant) do
			const owner = lookup[t]
			if owner == nil then
				lookup[t] = i
				table.insert(merged, t)
			elseif owner ~= i then
				error(`Duplicate "{t}" type used in union`)
			end
		end

		writes[i] = variant.write
		reads[i] = variant.read

		const size = variant.size
		if type(size) == "number" then
			static_sizes[i] = size
		else
			size_fns[i] = size
		end
	end

	const fallback = lookup.unknown

	const first_size = static_sizes[1]
	local uniform = first_size ~= -1
	for i = 2, count do
		if static_sizes[i] ~= first_size then
			uniform = false
			break
		end
	end

	const function pick(value)
		const value_typeof = typeof(value)
		const index = lookup[value_typeof] or fallback
		if not index then
			error(`Invalid union type {value_typeof}`)
		end
		return index
	end

	const size_fn = if uniform
		then 1 + first_size
		else function(value)
			const index = pick(value)
			const static_size = static_sizes[index]
			if static_size >= 0 then
				return 1 + static_size
			end
			return 1 + (size_fns[index] :: any)(value)
		end

	return create({
		type = merged,
		write = function(buff, offset, value, refs)
			const index = pick(value)
			buffer.writeu8(buff, offset, index - 1)
			return 1 + writes[index](buff, offset + 1, value, refs)
		end,
		read = function(buff, offset, refs)
			const tag = buffer.readu8(buff, offset)
			const read_fn = reads[tag + 1]
			if not read_fn then
				error(`Invalid union tag {tag}`)
			end
			const len, val = read_fn(buff, offset + 1, refs)
			return 1 + len, val
		end,
		size = size_fn,
	})
end

const intersect: Intersect = function(...)
	const parts = { ... } :: { DataType }
	const count = #parts
	assert(count >= 2, "intersect requires at least 2 types")

	const writes = table.create<<index<DataType, "write">>>(count)
	const reads = table.create<<index<DataType, "read">>>(count)

	local static_total = 0
	const dyn_sizes: { (any) -> number } = {}

	for i, part in parts do
		const part_types = get_types(part)
		assert(#part_types == 1 and part_types[1] == "table", "Intersect can only be used with tables")

		writes[i] = part.write
		reads[i] = part.read

		const size = part.size
		if type(size) == "number" then
			static_total += size
		else
			table.insert(dyn_sizes, size :: any)
		end
	end

	const dyn_count = #dyn_sizes
	const size_fn = if dyn_count == 0
		then static_total
		else function(value)
			local total = static_total
			for i = 1, dyn_count do
				total += dyn_sizes[i](value)
			end
			return total
		end

	return create({
		type = "table",
		write = function(buff, offset, value, refs)
			local pos = offset
			for i = 1, count do
				pos += writes[i](buff, pos, value, refs)
			end
			return pos - offset
		end,
		read = function(buff, offset, refs)
			const first_len, result = reads[1](buff, offset, refs)
			local pos = offset + first_len
			for i = 2, count do
				const len, val = reads[i](buff, pos, refs)
				pos += len
				for k, v in val do
					if result[k] ~= nil then
						warn(`key conflict with '{k}' in intersect, overwriting value`)
					end
					result[k] = v
				end
			end
			return pos - offset, result
		end,
		size = size_fn,
	})
end

const tuple: tuple<"10"> = function(...)
	const args = table.pack(...)
	return function()
		return table.unpack(args, 1, args.n)
	end
end :: any

return table.freeze({
	create = create,
	refine = refine,
	push_ref = push_ref,
	next_ref = next_ref,
	u8 = u8,
	u16 = u16,
	u32 = u32,
	i8 = i8,
	i16 = i16,
	i32 = i32,
	f16 = f16,
	f32 = f32,
	f64 = f64,
	boolean = boolean,
	string = string_ty,
	buffer = buffer_ty,
	unknown = unknown,
	none = none,
	vec = vec,
	vec2 = vec2,
	vec3 = vec3,
	cframe = cframe,
	color3 = color3,
	player = player,
	instance = instance,
	optional = optional,
	literal = literal,
	enum = enum,
	array = array,
	set = set,
	map = map,
	struct = struct,
	tagged = tagged,
	union = union,
	intersect = intersect,
	tuple = tuple,
})
