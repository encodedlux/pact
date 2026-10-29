const create = require("../create")
const null_ref = require("../null_ref")

return create<<Instance>>({
	write = function(buff, offset, value, refs)
		table.insert(refs, value or null_ref)
		return 0
	end,
	read = function(buff, offset, refs)
		refs.cursor += 1
		const instance: Instance = refs[refs.cursor]
		assert(typeof(instance) == "Instance", "Expected instance, but got " .. typeof(instance))
		return 0, instance
	end,
	size = 0,
})
