const create = require("../create")

return create<<nil>>({
	write = function()
		return 0
	end,
	read = function()
		return 0, nil
	end,
	size = 0,
})
