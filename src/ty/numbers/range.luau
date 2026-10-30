const function parse_float(range: { min: number?, max: number? }?)
	return function(value: number): (boolean, string?)
		if typeof(value) ~= "number" or value ~= value then
			return false, "value must be a valid number"
		end

		if range and ((range.min ~= nil and value < range.min) or (range.max ~= nil and value > range.max)) then
			return false, "value is not in range"
		end

		return true, nil
	end
end

const function parse_integer(range: { min: number?, max: number? }?)
	return function(value: number): (boolean, string?)
		if typeof(value) ~= "number" or value ~= value then
			return false, "value must be a valid number"
		end
		if math.floor(value) ~= value or value == math.huge or value == -math.huge then
			return false, "value must be an integer"
		end

		if range and ((range.min ~= nil and value < range.min) or (range.max ~= nil and value > range.max)) then
			return false, "value is not in range"
		end

		return true, nil
	end
end

return {
	parse_float = parse_float,
	parse_integer = parse_integer,
}
