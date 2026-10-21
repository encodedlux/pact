const create = require("../create")
const constants = require("../../constants")

const HALF_FLOAT = constants.HALF_FLOAT

const writeu16, readu16 = buffer.writeu16, buffer.readu16

const function writef16(b: buffer, offset: number, value: number)
	if value > 65504 then
		writeu16(b, offset, 0b0_11111_0000000000)
	elseif value < -65504 then
		writeu16(b, offset, 0b1_11111_0000000000)
	elseif value ~= value then
		writeu16(b, offset, 0b0_11111_0000000001)
	elseif value == 0 then
		writeu16(b, offset, 0)
	else
		const absValue = math.abs(value)
		const interval = math.ldexp(1, math.floor(math.log(absValue, 2)) - 10)
		const rounded_value = (absValue // interval) * interval
		local fraction, exponent = math.frexp(rounded_value)
		exponent += 14
		const mantissa = math.round(
			if exponent <= 0 then fraction * 0x400 / math.ldexp(1, math.abs(exponent)) else fraction * 0x800
		) % 0x400

		const result = mantissa + math.max(exponent, 0) * 0x400 + if value < 0 then 0x8000 else 0

		writeu16(b, offset, result)
	end
end

const function readf16(b: buffer, offset: number): number
	const encoded = readu16(b, offset)
	const mantissa_exponent = encoded % 0x8000

	if mantissa_exponent == 0b0_11111_0000000000 then
		return if encoded // 0x8000 == 1 then -math.huge else math.huge
	elseif mantissa_exponent > 0b0_11111_0000000000 then
		return 0 / 0
	elseif mantissa_exponent == 0 then
		return 0
	else
		const mantissa = mantissa_exponent % 0x400
		const exponent = mantissa_exponent // 0x400
		local fraction
		if exponent == 0 then
			fraction = mantissa / 0x400
		else
			fraction = mantissa / 0x800 + 0.5
		end
		const result = math.ldexp(fraction, exponent - 14)
		return if encoded // 0x8000 == 1 then -result else result
	end
end

return create<<number>>({
	write = @native function(buff, offset, value)
		writef16(buff, offset, value)
		return HALF_FLOAT
	end,
	read = @native function(buff, offset)
		return HALF_FLOAT, readf16(buff, offset)
	end,
	size = HALF_FLOAT,
})
