const create = require("../create")

return create<<nil>>({
	write = function()
		return 0
	end,
	read = function()
		return 0, nil
	end,
	size = 0,
	parse = function(value)
		if value ~= nil then
			return false, "value must be nil"
		end
		return true, nil
	end,
})
