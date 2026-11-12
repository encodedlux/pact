--!native
--!optimize 2

const RunService = game:GetService("RunService")

const casing = require("../util/casing")
const link = require("../network/link")
const types = require("../types")

type DefOptions = types.DefOptions
type Define<Objects, Options> = types.Define<Objects, Options>
type ServerObjects<Objects, Options> = types.ServerObjects<Objects, Options>
type ClientObjects<Objects, Options> = types.ClientObjects<Objects, Options>
type Link = link.Link

type DefObjects = {
	read [string]: DefObjects | types.Event | types.Funct | types.State,
}

const IS_SERVER = RunService:IsServer()

const names_cache: { [string]: true } = {}

const function define<Objects, Options>(
	name: string,
	objects: Objects & DefObjects,
	options: (Options & DefOptions)?
): Define<Objects, Options>
	if names_cache[name] then
		error(`"{name}" has already been defined.`)
	end
	names_cache[name] = true

	const opt: DefOptions = options or {}
	const method_names = casing.get_casing(opt.casing)

	local returns: any

	const function resolve_objects()
		if returns then
			return returns
		end

		const function resolve_objects_recursive(node: DefObjects, path: string, l: Link): any
			if type(node.constructor) == "function" then
				const object = node.constructor(opt, path, l)
				return if IS_SERVER then object.server else object.client
			end
			const resolved = {}
			for k, v: DefObjects in node do
				const next_path = if path ~= "" then path .. "." .. k else k
				resolved[k] = resolve_objects_recursive(v, next_path, l)
			end
			return resolved
		end

		const l = link.new(name, opt.auto_flush)
		returns = resolve_objects_recursive(objects, name, l)
		returns[method_names["flush"]] = l.transport.flush
		return table.freeze(returns)
	end

	const function def_server(): ServerObjects<Objects, Options>
		if not IS_SERVER then
			error(`Server def can only be accessed from the server.`)
		end
		return resolve_objects()
	end

	const function def_client(): ClientObjects<Objects, Options>
		if IS_SERVER then
			error(`Client def can only be accessed from the client.`)
		end
		return resolve_objects()
	end

	return setmetatable({}, {
		__index = function(_, key): ServerObjects<Objects, Options> | ClientObjects<Objects, Options>
			if key == "server" then
				return def_server()
			end
			if key == "client" then
				return def_client()
			end
			error(`Key "{key}" not found in "{name}".`)
		end,
	}) :: any
end

return define
