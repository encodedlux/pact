--!native
--!optimize 2

const RunService = game:GetService("RunService")

const constants = require("../constants")
const types = require("../types")

type BufferSave = types.BufferSave
type DataType = types.DataType

const IS_DEV = RunService:IsStudio()
const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME

const writeu8 = buffer.writeu8
const buffer_create, buffer_copy = buffer.create, buffer.copy

const function create_save(): BufferSave
	return { size = 256, cursor = 0, buff = buffer_create(256), refs = {} }
end

const function ensure(save: BufferSave, bytes: number)
	const required = save.cursor + bytes
	if required <= save.size then
		return
	end
	local new_size = save.size
	while new_size < required do
		new_size *= 2
	end
	const new_buff = buffer_create(new_size)
	buffer_copy(new_buff, 0, save.buff, 0, save.cursor)
	save.buff = new_buff
	save.size = new_size
end

const function build_write_args(args: { DataType }): (buffer, number, { [any]: any }, ...any) -> number
	const count = #args
	if count == 2 then
		const write1, write2 = args[1].write, args[2].write
		return function(buff, offset, refs, a1, a2)
			const len1 = write1(buff, offset, a1, refs)
			const len2 = write2(buff, offset + len1, a2, refs)
			return len1 + len2
		end
	elseif count == 3 then
		const write1, write2, write3 = args[1].write, args[2].write, args[3].write
		return function(buff, offset, refs, a1, a2, a3)
			const len1 = write1(buff, offset, a1, refs)
			const len2 = write2(buff, offset + len1, a2, refs)
			const len3 = write3(buff, offset + len1 + len2, a3, refs)
			return len1 + len2 + len3
		end
	elseif count == 4 then
		const write1, write2, write3, write4 = args[1].write, args[2].write, args[3].write, args[4].write
		return function(buff, offset, refs, a1, a2, a3, a4)
			const len1 = write1(buff, offset, a1, refs)
			const len2 = write2(buff, offset + len1, a2, refs)
			const len3 = write3(buff, offset + len1 + len2, a3, refs)
			const len4 = write4(buff, offset + len1 + len2 + len3, a4, refs)
			return len1 + len2 + len3 + len4
		end
	elseif count == 5 then
		const write1, write2, write3, write4, write5 =
			args[1].write, args[2].write, args[3].write, args[4].write, args[5].write
		return function(buff, offset, refs, a1, a2, a3, a4, a5)
			const len1 = write1(buff, offset, a1, refs)
			const len2 = write2(buff, offset + len1, a2, refs)
			const len3 = write3(buff, offset + len1 + len2, a3, refs)
			const len4 = write4(buff, offset + len1 + len2 + len3, a4, refs)
			const len5 = write5(buff, offset + len1 + len2 + len3 + len4, a5, refs)
			return len1 + len2 + len3 + len4 + len5
		end
	end
	return function(buff, offset, refs, ...)
		local bytes = 0
		for i = 1, count do
			bytes += args[i].write(buff, offset + bytes, select(i, ...), refs)
		end
		return bytes
	end
end

const function build_read_args(args: { DataType }): (buffer, number, { [any]: any }) -> (number, ...any)
	const count = #args
	if count == 1 then
		return args[1].read
	elseif count == 2 then
		const read1, read2 = args[1].read, args[2].read
		return function(buff, offset, refs)
			const len1, val1 = read1(buff, offset, refs)
			const len2, val2 = read2(buff, offset + len1, refs)
			return len1 + len2, val1, val2
		end
	elseif count == 3 then
		const read1, read2, read3 = args[1].read, args[2].read, args[3].read
		return function(buff, offset, refs)
			const len1, val1 = read1(buff, offset, refs)
			const len2, val2 = read2(buff, offset + len1, refs)
			const len3, val3 = read3(buff, offset + len1 + len2, refs)
			return len1 + len2 + len3, val1, val2, val3
		end
	elseif count == 4 then
		const read1, read2, read3, read4 = args[1].read, args[2].read, args[3].read, args[4].read
		return function(buff, offset, refs)
			const len1, val1 = read1(buff, offset, refs)
			const len2, val2 = read2(buff, offset + len1, refs)
			const len3, val3 = read3(buff, offset + len1 + len2, refs)
			const len4, val4 = read4(buff, offset + len1 + len2 + len3, refs)
			return len1 + len2 + len3 + len4, val1, val2, val3, val4
		end
	elseif count == 5 then
		const read1, read2, read3, read4, read5 = args[1].read, args[2].read, args[3].read, args[4].read, args[5].read
		return function(buff, offset, refs)
			const len1, val1 = read1(buff, offset, refs)
			const len2, val2 = read2(buff, offset + len1, refs)
			const len3, val3 = read3(buff, offset + len1 + len2, refs)
			const len4, val4 = read4(buff, offset + len1 + len2 + len3, refs)
			const len5, val5 = read5(buff, offset + len1 + len2 + len3 + len4, refs)
			return len1 + len2 + len3 + len4 + len5, val1, val2, val3, val4, val5
		end
	end
	return function(buff, offset, refs)
		local bytes = 0
		const results = table.create(count)
		for i = 1, count do
			local len, value = args[i].read(buff, offset + bytes, refs)
			bytes += len
			results[i] = value
		end
		return bytes, table.unpack(results, 1, count)
	end
end

const function build_args_size(args: { DataType }): index<DataType, "size">
	const count = #args
	if count == 1 then
		return args[1].size
	end

	local fixed_args = 0
	const var_idxs: { number } = {}
	const var_args_sizes: { (any) -> number } = {}
	for i = 1, count do
		const arg_size = args[i].size
		if type(arg_size) == "number" then
			fixed_args += arg_size
		else
			table.insert(var_idxs, i)
			table.insert(var_args_sizes, arg_size)
		end
	end

	if #var_idxs == 0 then
		return fixed_args
	end

	if count == 2 then
		const size1: any, size2: any = args[1].size, args[2].size
		const f1, f2 = type(size1) == "number", type(size2) == "number"
		return function(a1, a2)
			return (if f1 then size1 else size1(a1)) + (if f2 then size2 else size2(a2))
		end
	elseif count == 3 then
		const size1: any, size2: any, size3: any = args[1].size, args[2].size, args[3].size
		const f1, f2, f3 = type(size1) == "number", type(size2) == "number", type(size3) == "number"
		return function(a1, a2, a3)
			return (if f1 then size1 else size1(a1))
				+ (if f2 then size2 else size2(a2))
				+ (if f3 then size3 else size3(a3))
		end
	elseif count == 4 then
		const size1: any, size2: any, size3: any, size4: any = args[1].size, args[2].size, args[3].size, args[4].size
		const f1, f2, f3, f4 =
			type(size1) == "number", type(size2) == "number", type(size3) == "number", type(size4) == "number"
		return function(a1, a2, a3, a4)
			return (if f1 then size1 else size1(a1))
				+ (if f2 then size2 else size2(a2))
				+ (if f3 then size3 else size3(a3))
				+ (if f4 then size4 else size4(a4))
		end
	elseif count == 5 then
		const size1: any, size2: any, size3: any, size4: any, size5: any =
			args[1].size, args[2].size, args[3].size, args[4].size, args[5].size
		const f1, f2, f3, f4, f5 =
			type(size1) == "number",
			type(size2) == "number",
			type(size3) == "number",
			type(size4) == "number",
			type(size5) == "number"
		return function(a1, a2, a3, a4, a5)
			return (if f1 then size1 else size1(a1))
				+ (if f2 then size2 else size2(a2))
				+ (if f3 then size3 else size3(a3))
				+ (if f4 then size4 else size4(a4))
				+ (if f5 then size5 else size5(a5))
		end
	end

	return function(...)
		local total = fixed_args
		for idx, i in var_idxs do
			total += var_args_sizes[idx](select(i, ...))
		end
		return total
	end
end

const function build_write_event(args: { DataType }, id: number)
	const count = #args
	if count == 1 then
		const write = args[1].write
		const size = args[1].size
		const success_total = if type(size) == "number" then 1 + size else nil
		return function(save: BufferSave, value)
			const total = success_total or (1 + (size :: any)(value))
			ensure(save, total)
			const offset = save.cursor
			const buff = save.buff
			const refs = save.refs
			writeu8(buff, offset, id)
			const bytes = 1 + write(buff, offset + 1, value, refs)
			save.cursor += bytes
			if IS_DEV and total ~= bytes then
				warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
			end
		end
	end

	const write_args = build_write_args(args)
	const args_size = build_args_size(args)
	const success_total = if type(args_size) == "number" then 1 + args_size else nil
	return function(save: BufferSave, ...)
		const total = success_total or (1 + (args_size :: any)(...))
		ensure(save, total)
		const offset = save.cursor
		const buff = save.buff
		const refs = save.refs
		writeu8(buff, offset, id)
		const bytes = 1 + write_args(buff, offset + 1, refs, ...)
		save.cursor += bytes
		if IS_DEV and total ~= bytes then
			warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
		end
	end
end

const function build_write_funct_invoke(args: { DataType }, id: number)
	const count = #args
	if count == 1 then
		const write = args[1].write
		const size = args[1].size
		const success_total = if type(size) == "number" then 2 + size else nil
		return function(save: BufferSave, invocation_id: number, value)
			const total = success_total or (2 + (size :: any)(value))
			ensure(save, total)
			const offset = save.cursor
			const buff = save.buff
			const refs = save.refs
			writeu8(buff, offset, id)
			writeu8(buff, offset + 1, invocation_id)
			const bytes = 2 + write(buff, offset + 2, value, refs)
			save.cursor += bytes
			if IS_DEV and total ~= bytes then
				warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
			end
		end
	end

	const write_args = build_write_args(args)
	const args_size = build_args_size(args)
	const success_total = if type(args_size) == "number" then 2 + args_size else nil
	return function(save: BufferSave, invocation_id: number, ...)
		const total = success_total or (2 + (args_size :: any)(...))
		ensure(save, total)
		const offset = save.cursor
		const buff = save.buff
		const refs = save.refs
		writeu8(buff, offset, id)
		writeu8(buff, offset + 1, invocation_id)
		const bytes = 2 + write_args(buff, offset + 2, refs, ...)
		save.cursor += bytes
		if IS_DEV and total ~= bytes then
			warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
		end
	end
end

const function build_write_funct_ret(args: { DataType }, id: number)
	const count = #args
	if count == 1 then
		const write = args[1].write
		const size = args[1].size
		const success_total = if type(size) == "number" then 3 + size else nil
		return function(save: BufferSave, invocation_id: number, success: boolean, value)
			if success ~= true then
				ensure(save, 3)
				const offset = save.cursor
				const buff = save.buff
				writeu8(buff, offset, id)
				writeu8(buff, offset + 1, invocation_id)
				writeu8(buff, offset + 2, 0)
				save.cursor += 3
				return
			end
			const total = success_total or (3 + (size :: any)(value))
			ensure(save, total)
			const offset = save.cursor
			const buff = save.buff
			const refs = save.refs
			writeu8(buff, offset, id)
			writeu8(buff, offset + 1, invocation_id)
			writeu8(buff, offset + 2, 1)
			const bytes = 3 + write(buff, offset + 3, value, refs)
			save.cursor += bytes
			if IS_DEV and total ~= bytes then
				warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
			end
		end
	end

	const write_args = build_write_args(args)
	const args_size = build_args_size(args)
	const success_total = if type(args_size) == "number" then 3 + args_size else nil
	return function(save: BufferSave, invocation_id: number, success: boolean, ...)
		if not success then
			ensure(save, 3)
			const offset = save.cursor
			const buff = save.buff
			writeu8(buff, offset, id)
			writeu8(buff, offset + 1, invocation_id)
			writeu8(buff, offset + 2, 0)
			save.cursor += 3
			return
		end
		const total = success_total or (3 + (args_size :: any)(...))
		ensure(save, total)
		const offset = save.cursor
		const buff = save.buff
		const refs = save.refs
		writeu8(buff, offset, id)
		writeu8(buff, offset + 1, invocation_id)
		writeu8(buff, offset + 2, 1)
		const bytes = 3 + write_args(buff, offset + 3, refs, ...)
		save.cursor += bytes
		if IS_DEV and total ~= bytes then
			warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
		end
	end
end

const function write_event_to_players(
	players: { Player },
	saves: { [Player]: BufferSave },
	write: (BufferSave, ...any) -> (),
	exclude: Player?,
	...
)
	local serialized_buff: buffer
	local serialized_offset: number
	local serialized_bytes: number
	local source_refs: { any }
	local refs_start: number
	local refs_count: number = 0
	local is_serialized = false

	for _, player in players do
		if player == exclude then
			continue
		end
		const save = saves[player]
		if not save then
			continue
		end

		if is_serialized then
			ensure(save, serialized_bytes)
			const target_offset = save.cursor
			buffer_copy(save.buff, target_offset, serialized_buff, serialized_offset, serialized_bytes)
			save.cursor += serialized_bytes
			if refs_count > 0 then
				table.move(source_refs, refs_start, refs_start + refs_count - 1, #save.refs + 1, save.refs)
			end
		else
			const start_cursor = save.cursor
			const start_refs_count = #save.refs
			write(save, ...)
			serialized_buff = save.buff
			serialized_offset = start_cursor
			serialized_bytes = save.cursor - start_cursor
			source_refs = save.refs
			refs_start = start_refs_count + 1
			refs_count = #save.refs - start_refs_count
			is_serialized = true
		end
	end
end

return {
	create_save = create_save,
	build_read_args = build_read_args,
	build_write_event = build_write_event,
	build_write_funct_invoke = build_write_funct_invoke,
	build_write_funct_ret = build_write_funct_ret,
	write_event_to_players = write_event_to_players,
}
