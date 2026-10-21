const define = require("@self/api/define")
const event = require("@self/api/event")
const funct = require("@self/api/funct")
const state = require("@self/api/state")
const ty = require("@self/ty")
const types = require("@self/types")

export type DataType<T> = types.DataType<T>
export type Infer<T> = types.Infer<T>
export type InferFromFields<T> = types.InferFromFields<T>
export type InferFromTuple<T, I> = types.InferFromTuple<T, I>

return {
	define = define,
	event = event,
	funct = funct,
	state = state,

	t = ty,
}
