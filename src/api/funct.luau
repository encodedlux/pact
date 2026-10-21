--!native
--!optimize 2

const RunService = game:GetService("RunService")

const constants = require("../constants")
const casing = require("../util/casing")
const link = require("../runtime/link")
const serdes = require("../runtime/serdes")
const threads = require("../util/threads")
const types = require("../types")

type DataType = types.DataType
type BufferSave = types.BufferSave
type FunctProps = types.FunctProps
type Funct<Props> = types.Funct<Props>
type FunctServer<Props> = types.FunctServer<Props>
type FunctClient<Props> = types.FunctClient<Props>
type DefOptions = types.DefOptions
type Link = link.Link

const IS_SERVER = RunService:IsServer()
const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME

const spawn = threads.spawn

const readu8 = buffer.readu8

const function build_funct_on(path: string, lnk: Link, id: number, value_args: { DataType }, ret_args: { DataType })
	const write_funct_ret = serdes.build_write_funct_ret(ret_args, id)
	const read_args = serdes.build_read_args(value_args)

	const saves = lnk.transport.players_reliable

	const listeners = {} :: { (...any) -> ...any }

	const function run_dispatch(save: BufferSave, invocation_id: number, success: boolean, ...)
		if not save then
			return
		end
		write_funct_ret(save, invocation_id, success, ...)
	end

	const function result_read_return(invocation_id: number, bytes: number, ...)
		return 1 + bytes, invocation_id, ...
	end

	lnk.transport.read_fns[id] = function(buff, offset, refs)
		const invocation_id = readu8(buff, offset)
		return result_read_return(invocation_id, read_args(buff, offset + 1, refs))
	end

	lnk.transport.dispatches[id] = function(...)
		if listeners[1] then
			spawn(function(player, invocation_id, ...)
				run_dispatch(saves[player], invocation_id, pcall(listeners[1], player, ...))
			end, ...)
		else
			const player, invocation_id = ...
			const save = saves[player]
			if save then
				write_funct_ret(save, invocation_id, false)
			end
		end
	end

	return function(callback)
		if listeners[1] then
			warn(
				debug.traceback(
					`[{ROOT_SCOPE_NAME}]: Function "{path}" already has a callback, the callback will be overwritten`,
					2
				)
			)
		end
		listeners[1] = callback
		return function()
			listeners[1] = nil
		end
	end
end

const function build_funct_invoke(lnk: Link, id: number, value_args: { DataType }, ret_args: { DataType })
	const write_funct_invoke = serdes.build_write_funct_invoke(value_args, id)
	const read_args = serdes.build_read_args(ret_args)

	const save = lnk.transport.client_reliable
	const invocations = lnk.invocations

	const function result_read_return(invocation_id: number, success: boolean, bytes: number, ...)
		return 2 + bytes, success, invocation_id, ...
	end

	lnk.transport.read_fns[id] = function(buff, offset, refs)
		const invocation_id = readu8(buff, offset)
		const success = readu8(buff, offset + 1) == 1
		if not success then
			return 2, false, invocation_id
		end
		return result_read_return(invocation_id, success, read_args(buff, offset + 2, refs))
	end

	lnk.transport.dispatches[id] = function(success, invocation_id, ...)
		const thread = invocations[invocation_id]
		if thread ~= nil then
			invocations[invocation_id] = nil
			buffer.writeu8(lnk.invocations_stack, lnk.invocations_top, invocation_id)
			lnk.invocations_top += 1
			if coroutine.status(thread) == `suspended` then
				task.spawn(thread, success, ...)
			end
		end
	end

	const function result_invoke_return(success: boolean, ...)
		if not success then
			error(`[{ROOT_SCOPE_NAME}]: There was an exception while processing a response on the Server.`)
		end
		return ...
	end

	return function(...)
		if lnk.invocations_top == 0 then
			error(`[{ROOT_SCOPE_NAME}]: More than 256 pending responses. This invocation has been dropped.`)
		end
		lnk.invocations_top -= 1
		const invocation_id = buffer.readu8(lnk.invocations_stack, lnk.invocations_top)
		invocations[invocation_id] = coroutine.running()
		write_funct_invoke(save, invocation_id, ...)
		return result_invoke_return(coroutine.yield())
	end
end

const function funct<Props>(props: Props & FunctProps): Funct<Props>
	props = props :: FunctProps
	const value_args = if typeof(props.value) == "function" then { (props :: any).value() } else { props.value }
	const ret_args = if typeof(props.ret) == "function" then { (props :: any).ret() } else { props.ret }

	const function constructor(options: DefOptions, path: string, lnk: Link)
		assert(lnk.registered[path] == nil, `[{ROOT_SCOPE_NAME}]: Function "{path}" is already registered`)
		lnk.registered[path] = true

		const method_names = casing.get_casing(options.casing)

		const id = link.next_event_id(lnk, path)

		return {
			server = if IS_SERVER
				then {
					[method_names["on"]] = build_funct_on(path, lnk, id, value_args, ret_args),
				}
				else nil,
			client = if not IS_SERVER
				then {
					[method_names["invoke"]] = build_funct_invoke(lnk, id, value_args, ret_args),
				}
				else nil,
		}
	end

	return {
		type = "function",
		props = props,
		constructor = constructor,
	}
end

return funct
