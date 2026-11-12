const constants = {
	ROOT_SCOPE_NAME = "Pact" :: "Pact",
	ROOT_SCRIPT = script.Parent,

	casing = {
		values = {
			PascalCase = true,
			camelCase = true,
			snake_case = true,
		},
		default = "snake_case" :: "snake_case",
	},

	call = {
		values = {
			Sync = true,
			Async = true,
			Polling = true,
		},
		default = "Async" :: "Async",
	},
}

export type Constants = typeof(constants)

return constants
