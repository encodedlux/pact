const create = require("../create")

return create<<nil>>({
	write = @native function(buff, offset, value)
		return 0
	end,
	read = @native function(buff, offset)
		return 0, nil
	end,
	size = 0,
})
