-- NOTE: Overloaded up to a limit because generic `T...` breaks UDTF inspection (`Type:returns()`).
-- Revert back to `tuple<T...>(...: T...): () -> T...` once Luau supports generic type packs in UDTFs.
type function tuple(max_args: type)
	const count = max_args:is("singleton") and tonumber(max_args:value())
	local intersection = nil
	for args_count = 1, count :: number do
		const args: { type } = {}
		for i = 1, args_count do
			args[i] = types.generic("T" .. i)
		end
		const get_args = types.newfunction({}, { head = args })
		const tuple_fn = types.newfunction({ head = args }, { head = { get_args } }, args)
		intersection = if intersection then types.intersectionof(intersection, tuple_fn) else tuple_fn
	end
	return if intersection then intersection else types.singleton(nil)
end

const tuple: tuple<"20"> = function(...)
	const args = { ... }
	return @native function()
		return table.unpack(args)
	end
end

return tuple
