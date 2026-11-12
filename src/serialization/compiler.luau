--!native
--!optimize 2

const types = require("../types")
const writer = require("./writer")

type Writer = writer.Writer
type DataType = types.DataType

export type CompiledArgs<T... = ...any> = {
	args: { DataType },
	write: (buff: buffer, offset: number, refs: { [any]: any }, T...) -> number,
	read: (buff: buffer, offset: number, refs: { [any]: any }) -> (number, T...),
	fixed_size: number?,
	get_size: (T...) -> number,
}

const ensure = writer.ensure

const function build_write_args(args: { DataType }): index<CompiledArgs, "write">
	const count = #args
	if count == 0 then
		return function()
			return 0
		end
	elseif count == 1 then
		const write_fn = args[1].write
		return function(buff, offset, refs, a)
			return write_fn(buff, offset, a, refs)
		end
	elseif count == 2 then
		const write1, write2 = args[1].write, args[2].write
		return function(buff, offset, refs, a1, a2)
			const len1 = write1(buff, offset, a1, refs)
			return len1 + write2(buff, offset + len1, a2, refs)
		end
	elseif count == 3 then
		const write1, write2, write3 = args[1].write, args[2].write, args[3].write
		return function(buff, offset, refs, a1, a2, a3)
			local pos = offset
			pos += write1(buff, pos, a1, refs)
			pos += write2(buff, pos, a2, refs)
			pos += write3(buff, pos, a3, refs)
			return pos - offset
		end
	elseif count == 4 then
		const write1, write2, write3, write4 = args[1].write, args[2].write, args[3].write, args[4].write
		return function(buff, offset, refs, a1, a2, a3, a4)
			local pos = offset
			pos += write1(buff, pos, a1, refs)
			pos += write2(buff, pos, a2, refs)
			pos += write3(buff, pos, a3, refs)
			pos += write4(buff, pos, a4, refs)
			return pos - offset
		end
	end

	const write1, write2, write3, write4, write5 =
		args[1].write, args[2].write, args[3].write, args[4].write, args[5].write
	if count == 5 then
		return function(buff, offset, refs, a1, a2, a3, a4, a5)
			local pos = offset
			pos += write1(buff, pos, a1, refs)
			pos += write2(buff, pos, a2, refs)
			pos += write3(buff, pos, a3, refs)
			pos += write4(buff, pos, a4, refs)
			pos += write5(buff, pos, a5, refs)
			return pos - offset
		end
	end
	const writes = table.create<<index<DataType, "write">>>(count)
	for idx, arg in args do
		writes[idx] = arg.write
	end
	return function(buff, offset, refs, a1, a2, a3, a4, a5, ...)
		local pos = offset
		pos += write1(buff, pos, a1, refs)
		pos += write2(buff, pos, a2, refs)
		pos += write3(buff, pos, a3, refs)
		pos += write4(buff, pos, a4, refs)
		pos += write5(buff, pos, a5, refs)
		for i = 6, count do
			pos += writes[i](buff, pos, select(i - 5, ...), refs)
		end
		return pos - offset
	end
end

const function build_read_args(args: { DataType }): index<CompiledArgs, "read">
	const count = #args
	if count == 0 then
		return function()
			return 0
		end
	elseif count == 1 then
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
			local pos = offset
			const len1, val1 = read1(buff, pos, refs)
			pos += len1
			const len2, val2 = read2(buff, pos, refs)
			pos += len2
			const len3, val3 = read3(buff, pos, refs)
			pos += len3
			return pos - offset, val1, val2, val3
		end
	elseif count == 4 then
		const read1, read2, read3, read4 = args[1].read, args[2].read, args[3].read, args[4].read
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
			return pos - offset, val1, val2, val3, val4
		end
	end
	const read1, read2, read3, read4, read5 = args[1].read, args[2].read, args[3].read, args[4].read, args[5].read
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
			return pos - offset, val1, val2, val3, val4, val5
		end
	end
	const reads = table.create<<index<DataType, "read">>>(count)
	for idx, arg in args do
		reads[idx] = arg.read
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
		const results = table.create(count - 5)
		for i = 6, count do
			local len, value = reads[i](buff, pos, refs)
			pos += len
			results[i - 5] = value
		end
		return pos - offset, val1, val2, val3, val4, val5, table.unpack(results, 1, count - 5)
	end
end

const function build_args_size(args: { DataType }): index<CompiledArgs, "fixed_size"> | index<CompiledArgs, "get_size">
	const count = #args
	if count == 0 then
		return 0
	elseif count == 1 then
		return args[1].size :: any
	end

	local static_args = 0
	const dyn_indices: { number } = {}
	const dyn_args_sizes: { (any) -> number } = {}

	for i = 1, count do
		const arg_size = args[i].size
		if type(arg_size) == "number" then
			static_args += arg_size
		else
			table.insert(dyn_indices, i)
			table.insert(dyn_args_sizes, arg_size :: any)
		end
	end

	const dyn_count = #dyn_indices
	if dyn_count == 0 then
		return static_args
	elseif dyn_count == 1 then
		const idx1, s1 = dyn_indices[1], dyn_args_sizes[1]
		return function(...)
			return static_args + s1(select(idx1, ...))
		end
	elseif dyn_count == 2 then
		const idx1, idx2 = dyn_indices[1], dyn_indices[2]
		const s1, s2 = dyn_args_sizes[1], dyn_args_sizes[2]
		return function(...)
			return static_args + s1(select(idx1, ...)) + s2(select(idx2, ...))
		end
	elseif dyn_count == 3 then
		const idx1, idx2, idx3 = dyn_indices[1], dyn_indices[2], dyn_indices[3]
		const s1, s2, s3 = dyn_args_sizes[1], dyn_args_sizes[2], dyn_args_sizes[3]
		return function(...)
			return static_args + s1(select(idx1, ...)) + s2(select(idx2, ...)) + s3(select(idx3, ...))
		end
	elseif dyn_count == 4 then
		const idx1, idx2, idx3, idx4 = dyn_indices[1], dyn_indices[2], dyn_indices[3], dyn_indices[4]
		const s1, s2, s3, s4 = dyn_args_sizes[1], dyn_args_sizes[2], dyn_args_sizes[3], dyn_args_sizes[4]
		return function(...)
			return static_args
				+ s1(select(idx1, ...))
				+ s2(select(idx2, ...))
				+ s3(select(idx3, ...))
				+ s4(select(idx4, ...))
		end
	elseif dyn_count == 5 then
		const idx1, idx2, idx3, idx4, idx5 =
			dyn_indices[1], dyn_indices[2], dyn_indices[3], dyn_indices[4], dyn_indices[5]
		const s1, s2, s3, s4, s5 =
			dyn_args_sizes[1], dyn_args_sizes[2], dyn_args_sizes[3], dyn_args_sizes[4], dyn_args_sizes[5]
		return function(...)
			return static_args
				+ s1(select(idx1, ...))
				+ s2(select(idx2, ...))
				+ s3(select(idx3, ...))
				+ s4(select(idx4, ...))
				+ s5(select(idx5, ...))
		end
	end
	return function(...)
		local total = static_args
		for i = 1, dyn_count do
			total += dyn_args_sizes[i](select(dyn_indices[i], ...))
		end
		return total
	end
end

const function compile_args<T...>(value_type: any): CompiledArgs<T...>
	const args: { DataType } = if type(value_type) == "function" then { (value_type :: any)() } else { value_type }
	const args_size = build_args_size(args) :: any
	const static_size = type(args_size) == "number"
	return {
		args = args,
		write = build_write_args(args),
		read = build_read_args(args),
		fixed_size = if static_size then args_size else nil,
		get_size = if not static_size
			then args_size
			else function()
				return args_size
			end,
	}
end

const function build_write_event(compiled: CompiledArgs, id: number, ...)
	const fixed_size = compiled.fixed_size
	const get_size = compiled.get_size
	const args = compiled.args
	if #args == 1 then
		const write = args[1].write
		return function(w: Writer, value)
			const total = (fixed_size or get_size(value)) + 1
			ensure(w, total)
			const offset = w.cursor
			const buff = w.buff
			buffer.writeu8(buff, offset, id)
			const bytes = write(buff, offset + 1, value, w.refs) + 1
			w.cursor += bytes
			if total ~= bytes then
				error(`Data size mismatch, expected {total} but got {bytes}`)
			end
		end
	end
	const write_args = compiled.write
	return function(w: Writer, ...)
		const total = (fixed_size or get_size(...)) + 1
		ensure(w, total)
		const offset = w.cursor
		const buff = w.buff
		buffer.writeu8(buff, offset, id)
		const bytes = write_args(buff, offset + 1, w.refs, ...) + 1
		w.cursor += bytes
		if total ~= bytes then
			error(`Data size mismatch, expected {total} but got {bytes}`)
		end
	end
end

const function build_write_funct_invoke(compiled: CompiledArgs, id: number)
	const fixed_size = compiled.fixed_size
	const get_size = compiled.get_size
	const args = compiled.args
	if #args == 1 then
		const write = args[1].write
		return function(w: Writer, invocation_id: number, value)
			const total = (fixed_size or get_size(value)) + 2
			ensure(w, total)
			const offset = w.cursor
			const buff = w.buff
			buffer.writeu8(buff, offset, id)
			buffer.writeu8(buff, offset + 1, invocation_id)
			const bytes = write(buff, offset + 2, value, w.refs) + 2
			w.cursor += bytes
			if total ~= bytes then
				error(`Data size mismatch, expected {total} but got {bytes}`)
			end
		end
	end
	const write_args = compiled.write
	return function(w: Writer, invocation_id: number, ...)
		const total = (fixed_size or get_size(...)) + 2
		ensure(w, total)
		const offset = w.cursor
		const buff = w.buff
		buffer.writeu8(buff, offset, id)
		buffer.writeu8(buff, offset + 1, invocation_id)
		const bytes = write_args(buff, offset + 2, w.refs, ...) + 2
		w.cursor += bytes
		if total ~= bytes then
			error(`Data size mismatch, expected {total} but got {bytes}`)
		end
	end
end

const function build_write_funct_ret(compiled: CompiledArgs, id: number)
	const fixed_size = compiled.fixed_size
	const get_size = compiled.get_size
	const args = compiled.args
	if #args == 1 then
		const write = args[1].write
		return function(w: Writer, invocation_id: number, success: boolean, value)
			if not success then
				ensure(w, 3)
				const offset = w.cursor
				const buff = w.buff
				buffer.writeu8(buff, offset, id)
				buffer.writeu8(buff, offset + 1, invocation_id)
				buffer.writeu8(buff, offset + 2, 0)
				w.cursor += 3
				return
			end
			const total = (fixed_size or get_size(value)) + 3
			ensure(w, total)
			const offset = w.cursor
			const buff = w.buff
			buffer.writeu8(buff, offset, id)
			buffer.writeu8(buff, offset + 1, invocation_id)
			buffer.writeu8(buff, offset + 2, 1)
			const bytes = write(buff, offset + 3, value, w.refs) + 3
			w.cursor += bytes
			if total ~= bytes then
				error(`Data size mismatch, expected {total} but got {bytes}`)
			end
		end
	end
	const write_args = compiled.write
	return function(w: Writer, invocation_id: number, success: boolean, ...)
		if not success then
			ensure(w, 3)
			const offset = w.cursor
			const buff = w.buff
			buffer.writeu8(buff, offset, id)
			buffer.writeu8(buff, offset + 1, invocation_id)
			buffer.writeu8(buff, offset + 2, 0)
			w.cursor += 3
			return
		end
		const total = (fixed_size or get_size(...)) + 3
		ensure(w, total)
		const offset = w.cursor
		const buff = w.buff
		buffer.writeu8(buff, offset, id)
		buffer.writeu8(buff, offset + 1, invocation_id)
		buffer.writeu8(buff, offset + 2, 1)
		const bytes = write_args(buff, offset + 3, w.refs, ...) + 3
		w.cursor += bytes
		if total ~= bytes then
			error(`Data size mismatch, expected {total} but got {bytes}`)
		end
	end
end

return {
	compile_args = compile_args,
	build_write_event = build_write_event,
	build_write_funct_invoke = build_write_funct_invoke,
	build_write_funct_ret = build_write_funct_ret,
}
