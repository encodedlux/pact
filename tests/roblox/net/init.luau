const pact = require("./pact")

const define = pact.define
const event = pact.event
const funct = pact.funct
const state = pact.state
const t = pact.t

return define("test", {
	my_event = event({
		from = "Server",
		value = t.tuple(t.u8, t.string),
	}),
	other = event({
		from = "Client",
		call = "Polling",
		value = t.tuple(t.u8, t.string),
	}),
	scope = {
		my_func = funct({
			value = t.tuple(t.string, t.boolean),
			ret = t.enum("foo, bar"),
		}),
	},
	my_state = state({
		value = t.struct({
			count = t.u8,
		}),
		initial = {
			count = 0,
		},
	}),
}, {
	casing = "snake_case",
	default_call = "Sync",
	auto_flush = true,
})
