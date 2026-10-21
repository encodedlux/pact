const constants = {
	ROOT_SCOPE_NAME = "Pact" :: "Pact",
	ROOT_SCRIPT = script.Parent,

	BYTE = 1,
	SHORT = 2,
	INTEGER = 4,
	HALF_FLOAT = 2,
	FLOAT = 4,
	DOUBLE = 8,

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
