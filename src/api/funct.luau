--!native
--!optimize 2

const RunService = game:GetService("RunService")

const casing = require("../util/casing")
const compiler = require("../serialization/compiler")
const constants = require("../constants")
const link = require("../network/link")
const threads = require("../util/threads")
const types = require("../types")

type DataType = types.DataType
type FunctDecl = types.FunctDecl
type Funct<Decl> = types.Funct<Decl>
type FunctServer<Decl> = types.FunctServer<Decl>
type FunctClient<Decl> = types.FunctClient<Decl>
type DefOptions = types.DefOptions
type Link = link.Link
type CompiledArgs = compiler.CompiledArgs

const IS_SERVER = RunService:IsServer()
const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME

const spawn = threads.spawn

const readu8 = buffer.readu8

const function build_funct_on(
	path: string,
	l: Link,
	id: number,
	compiled_value: CompiledArgs,
	compiled_ret: CompiledArgs
)
	const write_funct_ret = compiler.build_write_funct_ret(compiled_ret, id)
	const read_args = compiled_value.read

	const player_writers = l.transport.player_writers

	local listener: (...any) -> ...any

	const function run_dispatch(w, invocation_id: number, success: boolean, ...)
		if not w then
			return
		end
		write_funct_ret(w, invocation_id, success, ...)
	end

	const function result_read_return(invocation_id: number, bytes: number, ...)
		return 1 + bytes, invocation_id, ...
	end

	l.transport.reads[id] = function(buff, offset, refs)
		const invocation_id = readu8(buff, offset)
		return result_read_return(invocation_id, read_args(buff, offset + 1, refs))
	end

	l.transport.dispatches[id] = function(...)
		if listener then
			spawn(function(player, invocation_id, ...)
				run_dispatch(player_writers[player], invocation_id, pcall(listener, player, ...))
			end, ...)
		else
			const player, invocation_id = ...
			const w = player_writers[player]
			if w then
				write_funct_ret(w, invocation_id, false)
			end
		end
	end

	return function(callback)
		if listener then
			warn(debug.traceback(`Function "{path}" already has a callback, the callback will be overwritten`))
		end
		listener = callback
		return function()
			listener = nil :: any
		end
	end
end

const function build_funct_invoke(l: Link, id: number, compiled_value: CompiledArgs, compiled_ret: CompiledArgs)
	const write_funct_invoke = compiler.build_write_funct_invoke(compiled_value, id)
	const read_args = compiled_ret.read

	const out_writer = l.transport.out_writer
	const invocations = l.invocations

	const function result_read_return(invocation_id: number, success: boolean, bytes: number, ...)
		return 2 + bytes, success, invocation_id, ...
	end

	l.transport.reads[id] = function(buff, offset, refs)
		const invocation_id = readu8(buff, offset)
		const success = readu8(buff, offset + 1) == 1
		if not success then
			return 2, false, invocation_id
		end
		return result_read_return(invocation_id, success, read_args(buff, offset + 2, refs))
	end

	l.transport.dispatches[id] = function(success, invocation_id, ...)
		const thread = invocations[invocation_id]
		if thread ~= nil then
			invocations[invocation_id] = nil
			buffer.writeu8(l.invocations_stack, l.invocations_top, invocation_id)
			l.invocations_top += 1
			if coroutine.status(thread) == `suspended` then
				task.spawn(thread, success, ...)
			end
		end
	end

	const function result_invoke_return(success: boolean, ...)
		if not success then
			error(`There was an exception while processing a response on the Server.`, 2)
		end
		return ...
	end

	return function(...)
		if l.invocations_top == 0 then
			error(`More than 256 pending responses. This invocation has been dropped.`)
		end
		l.invocations_top -= 1
		const invocation_id = buffer.readu8(l.invocations_stack, l.invocations_top)
		invocations[invocation_id] = coroutine.running()
		write_funct_invoke(out_writer, invocation_id, ...)
		return result_invoke_return(coroutine.yield())
	end
end

const function funct<Decl>(decl: Decl & FunctDecl): Funct<Decl>
	const decl = decl :: FunctDecl
	const compiled_value = compiler.compile_args(decl.value)
	const compiled_ret = compiler.compile_args(decl.ret)

	const function constructor(options: DefOptions, path: string, l: Link)
		assert(l.registered[path] == nil, `[{ROOT_SCOPE_NAME}]: Function "{path}" is already registered`)
		l.registered[path] = true

		const method_names = casing.get_casing(options.casing)
		const id = link.next_event_id(l, path)

		return {
			server = if IS_SERVER
				then {
					[method_names["on"]] = build_funct_on(path, l, id, compiled_value, compiled_ret),
				}
				else nil,
			client = if not IS_SERVER
				then {
					[method_names["invoke"]] = build_funct_invoke(l, id, compiled_value, compiled_ret),
				}
				else nil,
		}
	end

	return {
		type = "function",
		decl = decl,
		constructor = constructor,
	}
end

return funct
