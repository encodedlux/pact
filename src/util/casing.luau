--!native
--!optimize 2

const constants = require("../constants")

const DEFAULT_CASE = constants.casing.default

type Casing = index<constants.Constants, "casing">
export type Case = keyof<index<Casing, "values">>
export type DefaultCase = index<Casing, "default">

export type function get_casing(case: type?)
	const casing = types.newtable()
	const is_valid = case and case:is("singleton")
	for k, options in Cases:properties() do
		casing:setproperty(k, options.read:readproperty(if is_valid then case else DefaultCase))
	end
	return casing
end

const function build_case<Pascal, Camel, Snake>(
	pascal: Pascal | "",
	camel: Camel | "",
	snake: Snake | ""
): { PascalCase: Pascal, camelCase: Camel, snake_case: Snake }
	return {
		PascalCase = pascal,
		camelCase = camel,
		snake_case = snake,
	}
end

const cases = {
	server = build_case("Server", "server", "server"),
	client = build_case("Client", "client", "client"),
	flush = build_case("Flush", "flush", "flush"),
	fire = build_case("Fire", "fire", "fire"),
	fire_all = build_case("FireAll", "fireAll", "fire_all"),
	fire_list = build_case("FireList", "fireList", "fire_list"),
	fire_except = build_case("FireExcept", "fireExcept", "fire_except"),
	invoke = build_case("Invoke", "invoke", "invoke"),
	on = build_case("On", "on", "on"),
	collect = build_case("Collect", "collect", "collect"),
	set_client_view = build_case("SetClientView", "setClientView", "set_client_view"),
	set = build_case("Set", "set", "set"),
	get = build_case("Get", "get", "get"),
	selector = build_case("Selector", "selector", "selector"),
}

type Cases = typeof(cases)

const function get_casing<C>(case: (C | Case)?): get_casing<C>
	const casing = {}
	for k, options in cases :: any do
		casing[k] = options[case or DEFAULT_CASE]
	end
	return casing :: any
end

return {
	cases = cases,
	get_casing = get_casing,
}
