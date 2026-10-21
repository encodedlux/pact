--!native
--!optimize 2

const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const constants = require("../constants")
const casing = require("../util/casing")
const link = require("../runtime/link")
const queue = require("../util/queue")
const serdes = require("../runtime/serdes")
const threads = require("../util/threads")
const types = require("../types")

type DataType = types.DataType
type EventProps = types.EventProps
type Event<Props, Options> = types.Event<Props, Options>
type EventServer<Props, Options> = types.EventServer<Props, Options>
type EventClient<Props, Options> = types.EventClient<Props, Options>
type DefOptions = types.DefOptions
type Link = link.Link
type Queue = queue.Queue

const IS_SERVER = RunService:IsServer()
const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME

const create_queue = queue.create
const push = queue.push
const from_offset_queue = queue.from_offset
const clear_queue = queue.clear
const spawn_callbacks = threads.spawn_callbacks
const write_event_to_players = serdes.write_event_to_players

const function event<Props, Options>(props: Props & EventProps): Event<Props, Options>
	props = props :: EventProps
	const from = props.from
	const is_from_server = from == "Server" or from == nil
	const is_from_client = from == "Client" or from == nil
	const can_listen = (IS_SERVER and is_from_client) or (not IS_SERVER and is_from_server)
	const is_reliable = props.type ~= "Unreliable"

	const args: { DataType } = if typeof(props.value) == "function"
		then { (props :: any).value() }
		elseif props.value ~= nil then { props.value }
		else {}

	const function constructor(options: DefOptions, path: string, lnk: Link)
		assert(lnk.registered[path] == nil, `[{ROOT_SCOPE_NAME}]: Event "{path}" is already registered`)
		lnk.registered[path] = true

		const call = props.call or options.default_call or constants.call.default
		const use_polling = call == "Polling"

		const method_names = casing.get_casing(options.casing)

		const id = link.next_event_id(lnk, path)

		const listeners: { (...any) -> ...any } = {}
		const args_count = (if IS_SERVER then 1 else 0) + #args
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
						push(event_queues[i], ...)
					end
				end
				elseif call == "Sync" then function(...)
					if #listeners > 0 then
						for _, listener in listeners do
							listener(...)
						end
						return
					end
					push(event_queue, ...)
				end
				else function(...)
					if #listeners > 0 then
						spawn_callbacks(listeners, ...)
						return
					end
					push(event_queue, ...)
				end)
			else nil :: any

		if can_listen then
			lnk.transport.read_fns[id] = serdes.build_read_args(args) :: any
			lnk.transport.dispatches[id] = dispatch
		end

		if IS_SERVER then
			if is_from_server then
				const write_event = serdes.build_write_event(args, id)
				const saves = if is_reliable then lnk.transport.players_reliable else lnk.transport.players_unreliable

				fire_server = function(player: Player, ...)
					const save = saves[player]
					if not save then
						warn(
							debug.traceback(
								`[{ROOT_SCOPE_NAME}]: Failed to fire to "{player.Name}", they have already left the server.`,
								2
							)
						)
						return
					end
					write_event(save, ...)
				end
				fire_all = function(...)
					write_event_to_players(Players:GetPlayers(), saves, write_event, nil, ...)
				end
				fire_except = function(except: Player, ...)
					write_event_to_players(Players:GetPlayers(), saves, write_event, except, ...)
				end
				fire_list = function(players: { Player }, ...)
					write_event_to_players(players, saves, write_event, nil, ...)
				end
			end
		else
			if is_from_client then
				const write_event = serdes.build_write_event(args, id)
				const save = if is_reliable then lnk.transport.client_reliable else lnk.transport.client_unreliable

				fire_client = function(...)
					write_event(save, ...)
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
		props = props,
		constructor = constructor,
	}
end

return event
