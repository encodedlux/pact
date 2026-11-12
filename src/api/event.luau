--!native
--!optimize 2

const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const casing = require("../util/casing")
const compiler = require("../serialization/compiler")
const constants = require("../constants")
const link = require("../network/link")
const queue = require("../util/queue")
const threads = require("../util/threads")
const types = require("../types")
const writer = require("../serialization/writer")

type DataType = types.DataType
type EventDecl = types.EventDecl
type Event<Decl, Options> = types.Event<Decl, Options>
type EventServer<Decl, Options> = types.EventServer<Decl, Options>
type EventClient<Decl, Options> = types.EventClient<Decl, Options>
type DefOptions = types.DefOptions
type Link = link.Link

type Queue = {
	size: number,
	width: number,
	cursor: number,
	data: { any },
}

const IS_SERVER = RunService:IsServer()
const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME

const spawn_callbacks = threads.spawn_callbacks
const write_many = writer.write_many
const create_queue = queue.create
const push_queue = queue.push
const from_offset_queue = queue.from_offset
const clear_queue = queue.clear

const function event<Decl, Options>(decl: Decl & EventDecl): Event<Decl, Options>
	const decl = decl :: EventDecl
	const from = decl.from
	const is_from_server = from == "Server" or from == nil
	const is_from_client = from == "Client" or from == nil
	const can_listen = (IS_SERVER and is_from_client) or (not IS_SERVER and is_from_server)
	const is_reliable = decl.type ~= "Unreliable"

	const compiled = compiler.compile_args(decl.value)

	const function constructor(options: DefOptions, path: string, l: Link)
		assert(l.registered[path] == nil, `[{ROOT_SCOPE_NAME}]: Event "{path}" is already registered`)
		l.registered[path] = true

		const call = decl.call or options.default_call or constants.call.default
		const use_polling = call == "Polling"

		const unreliable_remote = l.transport.unreliable_remote
		const write_unreliable = l.transport.write_unreliable

		const method_names = casing.get_casing(options.casing)
		const id = link.next_event_id(l, path)

		const listeners: { (...any) -> ...any } = {}
		const args_count = (if IS_SERVER then 1 else 0) + #compiled.args
		const event_queues: { Queue } = {}

		local fire_server, fire_client, fire_all, fire_list, fire_except
		local on, collect

		local event_queue: Queue
		if can_listen and not use_polling then
			event_queue = create_queue(args_count)
			event_queues[1] = event_queue
		end

		const dispatch: (...any) -> () = if can_listen
			then (if use_polling
				then function(...)
					for i = 1, #event_queues do
						push_queue(event_queues[i], ...)
					end
				end
				elseif call == "Sync" then function(...)
					if #listeners > 0 then
						for _, listener in listeners do
							listener(...)
						end
						return
					end
					push_queue(event_queue, ...)
				end
				else function(...)
					if #listeners > 0 then
						spawn_callbacks(listeners, ...)
						return
					end
					push_queue(event_queue, ...)
				end)
			else nil :: any

		if can_listen then
			l.transport.reads[id] = compiled.read :: any
			l.transport.dispatches[id] = dispatch
		end

		if IS_SERVER then
			if is_from_server then
				const write_event = compiler.build_write_event(compiled, id)

				if is_reliable then
					const player_writers = l.transport.player_writers
					const out_writer = l.transport.out_writer

					fire_server = function(player: Player, ...)
						write_event(player_writers[player], ...)
					end

					fire_all = function(...)
						write_event(out_writer, ...)
					end

					fire_except = function(except: Player, ...)
						write_many(Players:GetPlayers(), player_writers, write_event, except, ...)
					end

					fire_list = function(players: { Player }, ...)
						write_many(players, player_writers, write_event, nil, ...)
					end
				else
					fire_server = function(player: Player, ...)
						unreliable_remote:FireClient(player, write_unreliable(write_event, ...))
					end

					fire_all = function(...)
						unreliable_remote:FireAllClients(write_unreliable(write_event, ...))
					end

					fire_except = function(except: Player, ...)
						const buff, refs = write_unreliable(write_event, ...)
						for _, player in Players:GetPlayers() do
							if player ~= except then
								unreliable_remote:FireClient(player, buff, refs)
							end
						end
					end

					fire_list = function(players: { Player }, ...)
						const buff, refs = write_unreliable(write_event, ...)
						for _, player in players do
							unreliable_remote:FireClient(player, buff, refs)
						end
					end
				end
			end
		else
			if is_from_client then
				const write_event = compiler.build_write_event(compiled, id)
				const out_writer = l.transport.out_writer

				if is_reliable then
					fire_client = function(...)
						write_event(out_writer, ...)
					end
				else
					fire_client = function(...)
						unreliable_remote:FireServer(write_unreliable(write_event, ...))
					end
				end
			end
		end

		if can_listen and not use_polling then
			on = function(callback)
				table.insert(listeners, callback)

				const size = event_queue.size
				if size > 0 then
					for i = 1, size do
						dispatch(from_offset_queue(event_queue, i))
					end
					clear_queue(event_queue)
				end

				return function()
					const idx = table.find(listeners, callback)
					if idx then
						table.remove(listeners, idx)
					end
				end
			end
		end

		if can_listen and use_polling then
			collect = function()
				const polling_queue = create_queue(args_count)
				table.insert(event_queues, polling_queue)

				return function()
					const offset = polling_queue.cursor + 1
					const size = polling_queue.size
					if offset > size then
						if size > 0 then
							clear_queue(polling_queue)
						end
						return nil :: any
					end
					polling_queue.cursor = offset
					return offset, from_offset_queue(polling_queue, offset)
				end, function()
					local idx = table.find(event_queues, polling_queue)
					if idx then
						table.remove(event_queues, idx)
						clear_queue(polling_queue)
					end
				end
			end
		end

		return {
			server = {
				[method_names["fire"]] = fire_server,
				[method_names["fire_all"]] = fire_all,
				[method_names["fire_list"]] = fire_list,
				[method_names["fire_except"]] = fire_except,
				[method_names["on"]] = on,
				[method_names["collect"]] = collect,
			},
			client = {
				[method_names["fire"]] = fire_client,
				[method_names["on"]] = on,
				[method_names["collect"]] = collect,
			},
		}
	end

	return {
		type = "event",
		decl = decl,
		constructor = constructor,
	}
end

return event
