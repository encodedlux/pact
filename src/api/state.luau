--!native
--!optimize 2

const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const constants = require("../constants")
const casing = require("../util/casing")
const link = require("../runtime/link")
const serdes = require("../runtime/serdes")
const ty = require("../ty")
const types = require("../types")

type Infer<T> = types.Infer<T>
type StateProps<T> = types.StateProps<T>
type State<T> = types.State<T>
type StateShared<T> = types.StateShared<T>
type StateServer<T> = types.StateServer<T>
type StateClient<T> = types.StateClient<T>
type DefOptions = types.DefOptions
type Selector<T, R> = types.Selector<T, R>
type Cleanup = types.Cleanup
type Link = link.Link

const IS_SERVER = RunService:IsServer()
const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME

const write_event_to_players = serdes.write_event_to_players

const function is_selector<T, R>(selector: Selector<T, R>): boolean
	return debug.info(selector, "n") == "selector_oper"
end

const function state<T>(props: StateProps<T>): State<Infer<T>>
	const value_type = props.value
	const initial_value = props.initial
	const value_args = {
		ty.tagged({
			request = {},
			dispatch = {
				value = value_type,
			},
		}) :: any,
	}

	const function constructor(options: DefOptions, path: string, lnk: Link)
		assert(lnk.registered[path] == nil, `[{ROOT_SCOPE_NAME}]: State "{path}" is already registered`)
		lnk.registered[path] = true

		const method_names = casing.get_casing(options.casing)

		const id = link.next_event_id(lnk, path)

		const write_state = serdes.build_write_event(value_args, id)
		const read_args = serdes.build_read_args(value_args)

		lnk.transport.read_fns[id] = read_args :: any

		local cache = initial_value
		const subs: { (any) -> () } = {}

		local view: ((player: Player, value: any) -> any)?

		const saves = lnk.transport.players_reliable

		const function notify(new_value)
			for _, sub in subs do
				sub(new_value)
			end
		end

		const function state_set(new_value: any)
			if new_value == cache then
				return
			end
			cache = new_value
			notify(new_value)
			if not IS_SERVER then
				return
			end
			if view then
				for _, player in Players:GetPlayers() do
					const save = saves[player]
					if save then
						write_state(save, { type = "dispatch", value = view(player, new_value) })
					end
				end
			else
				write_event_to_players(
					Players:GetPlayers(),
					saves,
					write_state,
					nil,
					{ type = "dispatch", value = new_value }
				)
			end
		end

		const state_selector: index<StateShared<any>, "selector"> = function(...)
			if select("#", ...) == 2 then
				local last_valueA
				local last_valueB
				const selectorA, selectorB = ...

				const function selector_oper(value): any
					const current_valueA = selectorA(value)
					if last_valueA == current_valueA then
						return last_valueB
					end
					last_valueA = current_valueA
					last_valueB = selectorB(current_valueA, last_valueB)
					return last_valueB
				end

				return selector_oper
			end
			local last_cache: any
			local last_value: any
			const selector = ...

			const function selector_oper(value)
				if last_cache == value then
					return last_value
				end
				last_cache = value
				last_value = selector(value, last_value)
				return last_value
			end

			return selector_oper
		end

		const function state_sub<R>(callback: (new: R, prev: R?) -> (), selector: Selector<any, R>?)
			local current
			const tracked: Selector<any, any> = selector
				and if is_selector(selector) then selector else state_selector(selector) :: any
			const function sub(value)
				const previous = current
				current = if tracked then tracked(value) else value
				if current ~= previous then
					callback(current, previous)
				end
			end
			current = if tracked then tracked(cache) else cache
			table.insert(subs, sub)
			return function()
				const idx = table.find(subs, sub)
				if idx then
					table.remove(subs, idx)
				end
			end
		end

		const state_on: index<StateShared<any>, "on"> = function(...)
			if select("#", ...) == 2 then
				const selector, callback = ...
				return state_sub(callback, selector)
			end
			const callback = ...
			return state_sub(callback)
		end

		const state_get: index<StateShared<any>, "get"> = function(selector)
			if selector then
				return selector(cache)
			end
			return cache
		end :: any

		if IS_SERVER then
			lnk.transport.dispatches[id] = function(player: Player, data: any)
				if data.type == "request" then
					const save = saves[player]
					if save then
						write_state(save, {
							type = "dispatch",
							value = if view then view(player, cache) else cache,
						})
					end
				end
			end
		else
			const save = lnk.transport.client_reliable

			write_state(save, { type = "request" })

			lnk.transport.dispatches[id] = function(data)
				if data.type == "dispatch" then
					cache = data.value
					notify(cache)
				end
			end
		end

		return {
			server = if IS_SERVER
				then {
					[method_names["set_client_view"]] = function(view_fn)
						if view then
							warn(
								debug.traceback(
									`[{ROOT_SCOPE_NAME}]: State "{path}" already has a client view, the view will be overwritten`,
									2
								)
							)
						end
						view = view_fn
					end,
					[method_names["set"]] = function(value_or_cb)
						if typeof(value_or_cb) == "function" then
							const new_value = (value_or_cb :: any)(cache)
							if new_value == false then
								return
							end
							state_set(new_value)
						else
							state_set(value_or_cb)
						end
					end,
					[method_names["selector"]] = state_selector,
					[method_names["on"]] = state_on,
					[method_names["get"]] = state_get,
				}
				else nil,
			client = if not IS_SERVER
				then {
					[method_names["selector"]] = state_selector,
					[method_names["on"]] = state_on,
					[method_names["get"]] = state_get,
				}
				else nil,
		}
	end

	return {
		type = "state",
		constructor = constructor,
	}
end

return state
