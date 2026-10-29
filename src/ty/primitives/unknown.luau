const create = require("../create")
const null_ref = require("../null_ref")

return create<<unknown>>({
	write = function(buff, offset, value, refs)
		table.insert(refs, value or null_ref)
		return 0
	end,
	read = function(buff, offset, refs)
		refs.cursor += 1
		return 0, refs[refs.cursor]
	end,
	size = 0,
})
