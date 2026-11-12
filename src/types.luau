const casing = require("./util/casing")
const constants = require("./constants")
const ty = require("./ty")

export type EventCall = keyof<index<index<constants.Constants, "call">, "values">>
export type Case = casing.Case
export type get_casing<T> = casing.get_casing<T>

export type DataType<T = any> = ty.DataType<T>
export type Infer<T> = ty.Infer<T>
export type InferFromFields<T> = ty.infer_from_fields<T>
export type InferFromTuple<T, I> = ty.infer_from_tuple<T, I>

export type EventDecl = {
	read from: ("Server" | "Client")?,
	read type: ("Reliable" | "Unreliable")?,
	read call: EventCall?,
	read value: any?,
}

export type FunctDecl = {
	read value: any?,
	read ret: any?,
}

export type StateDecl<T> = {
	read value: T,
	read initial: Infer<T>,
}

export type DefOptions = {
	read casing: Case?,
	read default_call: EventCall?,
	read auto_flush: (true | false)?,
}

type function data_type_input(ty: type)
	if not ty then
		return types.newfunction()
	end
	if ty:is("table") then
		return types.newfunction({ head = { Infer(ty) } })
	end
	if not ty:is("function") then
		return types.newfunction()
	end
	const returns = ty:returns()
	const head = returns.head or {}
	const new_head = {}
	for i, value in head do
		new_head[i] = Infer(value)
	end
	return types.newfunction({ head = new_head, tail = returns.tail })
end

type function merge(...: type)
	const result = types.newtable()
	const function copy_props(target: type)
		if target:is("table") then
			for k, prop in target:properties() do
				if prop.read then
					result:setproperty(k, prop.read)
				end
			end
		elseif target:is("intersection") then
			for _, component in target:components() do
				copy_props(component)
			end
		end
	end
	for i = 1, select("#", ...) do
		const t = select(i, ...)
		if t then
			copy_props(t)
		end
	end
	return result
end

type FireOnServer<T...> = {
	fire: (player: Player, T...) -> (),
	fire_all: (T...) -> (),
	fire_list: (players: { Player }, T...) -> (),
	fire_except: (player: Player, T...) -> (),
}

type FireOnClient<T...> = {
	fire: (T...) -> (),
}

type ListenOnServer<T...> = {
	on: (callback: (player: Player, T...) -> ()) -> Cleanup,
}

type ListenOnClient<T...> = {
	on: (callback: (T...) -> ()) -> Cleanup,
}

type CollectOnServer<T...> = {
	collect: () -> (() -> (number, Player, T...), Cleanup),
}

type CollectOnClient<T...> = {
	collect: () -> (() -> (number, T...), Cleanup),
}

export type function EventServer(decl: type, options: type)
	const from = decl:readproperty(types.singleton("from"))
	const value = decl:readproperty(types.singleton("value")) or types.singleton(nil)
	const call = decl:readproperty(types.singleton("call"))
	const default_call = options:is("table") and options:readproperty(types.singleton("default_call"))
	const use_polling = (call == types.singleton("Polling")) or (default_call == types.singleton("Polling"))
	const value_args = data_type_input(value):parameters().head or {}
	local result = types.newtable()
	if from ~= types.singleton("Client") then
		result = merge(result, FireOnServer(table.unpack(value_args)))
	end
	if from ~= types.singleton("Server") then
		if use_polling then
			result = merge(result, CollectOnServer(table.unpack(value_args)))
		else
			result = merge(result, ListenOnServer(table.unpack(value_args)))
		end
	end
	return result
end

export type function EventClient(decl: type, options: type)
	const from = decl:readproperty(types.singleton("from"))
	const value = decl:readproperty(types.singleton("value")) or types.singleton(nil)
	const call = decl:readproperty(types.singleton("call"))
	const default_call = options:is("table") and options:readproperty(types.singleton("default_call"))
	const use_polling = (call == types.singleton("Polling")) or (default_call == types.singleton("Polling"))
	const value_args = data_type_input(value):parameters().head or {}
	local result = types.newtable()
	if from ~= types.singleton("Server") then
		result = merge(result, FireOnClient(table.unpack(value_args)))
	end
	if from ~= types.singleton("Client") then
		if use_polling then
			result = merge(result, CollectOnClient(table.unpack(value_args)))
		else
			result = merge(result, ListenOnClient(table.unpack(value_args)))
		end
	end
	return result
end

export type EventConstructor<Decl = EventDecl, Options = DefOptions> = (
	options: Options & DefOptions,
	path: string,
	l: any
) -> {
	server: EventServer<Decl, Options>,
	client: EventClient<Decl, Options>,
}

export type Event<Decl = EventDecl, Options = DefOptions> = {
	type: "event",
	decl: Decl,
	constructor: EventConstructor<Decl, Options>,
}

type player = Player

export type function FunctServer(decl: type)
	const value = decl:readproperty(types.singleton("value")) or types.singleton(nil)
	const ret = decl:readproperty(types.singleton("ret")) or types.singleton(nil)
	const value_params = data_type_input(value):parameters()
	const ret_params = data_type_input(ret):parameters()
	const result = types.newtable()
	const head = { player }
	if value_params.head then
		table.move(value_params.head, 1, #value_params.head, #head + 1, head)
	end
	const cb_fn = types.newfunction({ head = head }, ret_params)
	const disconnect_fn = types.newfunction()
	result:setproperty(types.singleton("on"), types.newfunction({ head = { cb_fn } }, { head = { disconnect_fn } }))
	return result
end

export type function FunctClient(decl: type)
	const value = decl:readproperty(types.singleton("value")) or types.singleton(nil)
	const ret = decl:readproperty(types.singleton("ret")) or types.singleton(nil)
	const value_params = data_type_input(value):parameters()
	const ret_params = data_type_input(ret):parameters()
	const result = types.newtable()
	result:setproperty(types.singleton("invoke"), types.newfunction(value_params, ret_params))
	return result
end

export type FunctConstructor<Decl = FunctDecl> = (options: DefOptions, path: string, l: any) -> {
	server: FunctServer<Decl>,
	client: FunctClient<Decl>,
}

export type Funct<Decl = FunctDecl> = {
	type: "function",
	decl: Decl,
	constructor: FunctConstructor<Decl>,
}

export type Selector<T, R> = (value: T) -> R
export type Cleanup = () -> ()

export type StateShared<T> = {
	selector: (<R>(selector: (value: T, prev: R?) -> R) -> Selector<T, R>)
		& (<RI, R0>(selectorA: Selector<T, RI>, selectorB: (value: RI, prev: R0?) -> R0) -> Selector<T, R0>),
	on: ((callback: (new: T, prev: T?) -> ()) -> Cleanup) & (<R>(selector: Selector<T, R>, callback: (new: R, prev: R?) -> ()) -> Cleanup),
	get: (() -> T) & (<R>(selector: Selector<T, R>) -> R),
}

export type StateServer<T> = {
	set_client_view: (callback: (player: Player, value: T) -> T) -> (),
	set: ((value: T) -> ()) & ((callback: (value: T) -> T | false) -> ()),
	selector: index<StateShared<T>, "selector">,
	on: index<StateShared<T>, "on">,
	get: index<StateShared<T>, "get">,
}

export type StateClient<T> = StateShared<T>

export type StateConstructor<T = unknown> = (options: DefOptions, path: string, l: any) -> {
	server: StateServer<T>,
	client: StateClient<T>,
}

export type State<T = unknown> = {
	type: "state",
	constructor: StateConstructor<T>,
}

type function format_interface_casing(tbl: type, method_names: type)
	const returns = types.newtable()
	for k, prop in tbl:properties() do
		const format_key = method_names:readproperty(k) :: type
		if prop.read then
			returns:setproperty(format_key, prop.read)
		end
	end
	return returns
end

type function resolve_objects(objects: type, options: type, from: type)
	assert(objects:is("table"), "Expected a table")
	const casing = options:is("table") and options:readproperty(types.singleton("casing")) or types.unknown
	const auto_flush = options:is("table") and options:readproperty(types.singleton("auto_flush"))
	const is_server = (from == types.singleton("Server"))
	const method_names = get_casing(casing)
	const function resolve_objects_recursive(ty: type): type
		if ty:is("table") then
			const kind = ty:readproperty(types.singleton("type"))
			local ret: type?
			if kind == types.singleton("event") then
				const decl = ty:readproperty(types.singleton("decl"))
				const constructor_fn: type = EventConstructor(decl, options)
				const ctor_returns = constructor_fn:returns()
				const object = ctor_returns and ctor_returns.head and ctor_returns.head[1] :: type?
				ret = object and object:readproperty(types.singleton(is_server and "server" or "client"))
			elseif kind == types.singleton("function") then
				const decl = ty:readproperty(types.singleton("decl"))
				const constructor_fn: type = FunctConstructor(decl)
				const ctor_returns = constructor_fn:returns()
				const object = ctor_returns and ctor_returns.head and ctor_returns.head[1] :: type?
				ret = object and object:readproperty(types.singleton(is_server and "server" or "client"))
			elseif kind == types.singleton("state") then
				const constructor = ty:readproperty(types.singleton("constructor"))
				const ctor_returns = constructor and constructor:returns()
				const object = ctor_returns and ctor_returns.head and ctor_returns.head[1] :: type?
				ret = object and object:readproperty(types.singleton(is_server and "server" or "client"))
			end
			if ret then
				return format_interface_casing(ret, method_names)
			end
			const new = types.newtable()
			for k, prop in ty:properties() do
				if prop.read then
					new:setproperty(k, resolve_objects_recursive(prop.read))
				end
			end
			return new
		end
		return ty
	end

	const returns = resolve_objects_recursive(objects)
	if auto_flush == types.singleton(false) then
		returns:setproperty(method_names:readproperty(types.singleton("flush")), types.newfunction())
	end
	return returns
end

export type ServerObjects<Objects, Options> = resolve_objects<Objects, Options, "Server">
export type ClientObjects<Objects, Options> = resolve_objects<Objects, Options, "Client">

export type Define<Objects, Options> = {
	server: ServerObjects<Objects, Options>,
	client: ClientObjects<Objects, Options>,
}

return nil
