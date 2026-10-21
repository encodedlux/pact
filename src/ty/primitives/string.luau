const create = require("../create")
const constants = require("../../constants")

const SHORT = constants.SHORT

const writeu16, readu16, writestring, readstring =
	buffer.writeu16, buffer.readu16, buffer.writestring, buffer.readstring
const string_len = string.len

return create<<string>>({
	write = @native function(buff, offset, value)
		const len = string_len(value)
		writeu16(buff, offset, len)
		writestring(buff, offset + SHORT, value)
		return SHORT + len
	end,
	read = @native function(buff, offset)
		const len = readu16(buff, offset)
		return SHORT + len, readstring(buff, offset + SHORT, len)
	end,
	size = @native function(value: string)
		return SHORT + string_len(value)
	end,
})
