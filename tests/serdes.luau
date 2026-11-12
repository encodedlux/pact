const env = getfenv(0)

const roblox = require("@lune/roblox")
env.Vector2 = roblox.Vector2
env.Vector3 = roblox.Vector3
env.Color3 = roblox.Color3
env.CFrame = roblox.CFrame
env.Instance = roblox.Instance

env.script = {
	Parent = {
		Name = "Pact",
	},
}

env.game = {
	GetService = function(_, serviceName)
		if serviceName == "Players" then
			return {
				GetPlayerByUserId = function(_, userId)
					return { UserId = userId, Name = `Player_{userId}` }
				end,
			}
		end
		error(`Invalid service name: {serviceName}`)
	end,
}

const compiler = require("../src/serialization/compiler")
const ty = require("../src/ty")
const types = require("../src/types")

type DataType = types.DataType
type Infer<T> = types.Infer<T>

const function approx(a: number, b: number, epsilon: number?): boolean
	return math.abs(a - b) <= (epsilon or 0.001)
end

const function deep_equal(a: any, b: any): boolean
	if a == b then
		return true
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	for k, v in a do
		if not deep_equal(v, b[k]) then
			return false
		end
	end
	for k, v in b do
		if not deep_equal(v, a[k]) then
			return false
		end
	end
	return true
end

const function roundtrip<T>(value_type: T, value: Infer<T>): Infer<T>
	const compiled = compiler.compile_args<<(Infer<T>)>>(value_type)
	const expected_size = compiled.fixed_size or compiled.get_size(value)
	const buff, refs = buffer.create(expected_size), {}

	const written = compiled.write(buff, 0, refs, value)
	assert(written == expected_size, `write size mismatch: expected {expected_size}, got {written}`)

	refs.cursor = 0
	const read_len, decoded = compiled.read(buff, 0, refs)
	assert(read_len == expected_size, `read size mismatch: expected {expected_size}, got {read_len}`)

	return decoded
end

const function roundtrip_tuple<T...>(tuple_type: any, ...: T...): T...
	const compiled = compiler.compile_args(tuple_type)
	const expected_size = compiled.fixed_size or compiled.get_size(...)
	const buff, refs = buffer.create(expected_size), {}

	const written = compiled.write(buff, 0, refs, ...)
	assert(written == expected_size, `Tuple write size mismatch: expected {expected_size}, got {written}`)

	refs.cursor = 0
	const function run(_, ...)
		return ...
	end
	return run(compiled.read(buff, 0, refs))
end

-- primitives

-- integers

assert(roundtrip(ty.u8, 0) == 0, "u8 min failed")
assert(roundtrip(ty.u8, 255) == 255, "u8 max failed")
assert(roundtrip(ty.u16, 0) == 0, "u16 min failed")
assert(roundtrip(ty.u16, 65535) == 65535, "u16 max failed")
assert(roundtrip(ty.u32, 0) == 0, "u32 min failed")
assert(roundtrip(ty.u32, 4294967295) == 4294967295, "u32 max failed")

assert(roundtrip(ty.i8, -128) == -128, "i8 min failed")
assert(roundtrip(ty.i8, 127) == 127, "i8 max failed")
assert(roundtrip(ty.i16, -32768) == -32768, "i16 min failed")
assert(roundtrip(ty.i16, 32767) == 32767, "i16 max failed")
assert(roundtrip(ty.i32, -2147483648) == -2147483648, "i32 min failed")
assert(roundtrip(ty.i32, 2147483647) == 2147483647, "i32 max failed")

-- floats

assert(approx(roundtrip(ty.f16, 12.5), 12.5, 0.05), "f16 precision lost")
assert(approx(roundtrip(ty.f16, -45.25), -45.25, 0.05), "f16 negative failed")
assert(approx(roundtrip(ty.f32, 123.456), 123.456), "f32 precision lost")
assert(approx(roundtrip(ty.f32, -987.654), -987.654), "f32 negative failed")
assert(approx(roundtrip(ty.f64, 987654321.1234567), 987654321.1234567, 0.000001), "f64 precision lost")
assert(approx(roundtrip(ty.f64, -123456789.9876543), -123456789.9876543, 0.000001), "f64 negative failed")

-- boolean

assert(roundtrip(ty.boolean, true) == true, "boolean true failed")
assert(roundtrip(ty.boolean, false) == false, "boolean false failed")

-- string

assert(roundtrip(ty.string, "") == "", "empty string failed")
assert(roundtrip(ty.string, "Hello World!") == "Hello World!", "ascii string failed")
assert(roundtrip(ty.string, "Hello World! 🚀") == "Hello World! 🚀", "utf8 string failed")

-- buffer

const test_raw_buf = buffer.create(4)
buffer.writeu8(test_raw_buf, 0, 0xAA)
buffer.writeu8(test_raw_buf, 1, 0xBB)
buffer.writeu8(test_raw_buf, 2, 0xCC)
buffer.writeu8(test_raw_buf, 3, 0xDD)
const out_raw_buf = roundtrip(ty.buffer, test_raw_buf)
assert(buffer.len(out_raw_buf) == 4, "buffer len mismatch")
assert(buffer.readu8(out_raw_buf, 0) == 0xAA and buffer.readu8(out_raw_buf, 3) == 0xDD, "buffer contents mismatch")

-- none

assert(roundtrip(ty.none, nil) == nil, "none failed")
assert(roundtrip((nil :: any) :: typeof(ty.none), nil) == nil, "nil type failed")

-- unknown

assert(roundtrip(ty.unknown, 123) == 123, "unknown number failed")
assert(roundtrip(ty.unknown, "test") == "test", "unknown string failed")
assert(roundtrip(ty.unknown, false) == false, "unknown false failed")
assert(roundtrip(ty.unknown, nil) == nil, "unknown nil failed")
assert(deep_equal(roundtrip(ty.unknown, { a = 1, b = "two" }), { a = 1, b = "two" }), "unknown table failed")

-- vector

const vec = vector.create(-5.75, 10.5, 20.25)
const out_vec = roundtrip(ty.vec, vec)
assert(approx(out_vec.x, vec.x) and approx(out_vec.y, vec.y) and approx(out_vec.z, vec.z), "vec mismatch")

-- roblox

-- vector2

const v2 = Vector2.new(10.5, -20.25)
const out_v2 = roundtrip(ty.vec2, v2)
assert(approx(out_v2.X, v2.X) and approx(out_v2.Y, v2.Y), "vec2 mismatch")

-- vector3

const v3 = Vector3.new(-10.5, 20.25, 30.75)
const out_v3 = roundtrip(ty.vec3, v3)
assert(approx(out_v3.X, v3.X) and approx(out_v3.Y, v3.Y) and approx(out_v3.Z, v3.Z), "vec3 mismatch")

-- cframe

const cf = CFrame.new(12, 34, 56) * CFrame.Angles(0.1, 0.2, 0.3)
const out_cf = roundtrip(ty.cframe, cf)
const cx, cy, cz = out_cf:GetComponents()
const ox, oy, oz = cf:GetComponents()
assert(approx(cx, ox, 0.05) and approx(cy, oy, 0.05) and approx(cz, oz, 0.05), "cframe position mismatch")

-- color3

const c3 = Color3.fromRGB(50, 150, 200)
const out_c3 = roundtrip(ty.color3, c3)
assert(approx(out_c3.R, c3.R, 0.01) and approx(out_c3.G, c3.G, 0.01) and approx(out_c3.B, c3.B, 0.01), "color3 mismatch")

-- instances

const folder = Instance.new("Folder")
folder.Name = "TestFolder"
const out_inst = roundtrip(ty.instance, folder)
assert(out_inst == folder, "instance ref identity mismatch")

const mock_player = { UserId = 12345678 }
const out_player = roundtrip(ty.player, mock_player :: any)
assert(out_player and out_player.UserId == 12345678, "player mismatch")

-- optional

const opt_num = ty.optional(ty.u16)
assert(roundtrip(opt_num, nil) == nil, "optional nil failed")
assert(roundtrip(opt_num, 500) == 500, "optional value failed")

const opt_str = ty.optional(ty.string)
assert(roundtrip(opt_str, nil) == nil, "optional string nil failed")
assert(roundtrip(opt_str, "Pact") == "Pact", "optional string value failed")

-- structures

-- array

const arr_num = ty.array(ty.u8)
const num_list = { 10, 20, 30, 40, 50 }
assert(deep_equal(roundtrip(arr_num, num_list), num_list), "u8 array mismatch")

const arr_bool = ty.array(ty.boolean)
const bool_list = { true, false, true, true, false, true }
const out_bools = roundtrip(arr_bool, bool_list)
assert(deep_equal(out_bools, bool_list), "bitpacked boolean array mismatch")

const arr_str = ty.array(ty.string)
const str_list = { "alpha", "beta", "gamma" }
assert(deep_equal(roundtrip(arr_str, str_list), str_list), "string array mismatch")

-- struct

const player_struct = ty.struct({
	id = ty.u32,
	name = ty.string,
	level = ty.u16,
	is_vip = ty.boolean,
})
const struct_data = {
	id = 1001,
	name = "Steve",
	level = 50,
	is_vip = true,
}
const out_struct = roundtrip(player_struct, struct_data)
assert(deep_equal(out_struct, struct_data), "struct mismatch")

const combat_struct = ty.struct({
	player = player_struct,
	position = ty.vec3,
	score = ty.u32,
})
const combat_data = {
	player = struct_data,
	position = Vector3.new(1, 2, 3),
	score = 9999,
}
const out_combat = roundtrip(combat_struct, combat_data)
assert(deep_equal(out_combat.player, struct_data), "nested struct player mismatch")
assert(approx(out_combat.position.X, 1) and out_combat.score == 9999, "nested struct data mismatch")

-- map

const score_map = ty.map(ty.string, ty.u32)
const map_data: { [string]: number } = { Alice = 1000, Bob = 2500 }
const out_map = roundtrip(score_map, map_data)
assert(out_map.Alice == 1000 and out_map.Bob == 2500, "map mismatch")

-- set

const tag_set = ty.set(ty.string)
const set_data: { [string]: true } = { Admin = true, Mod = true, Tester = true }
const out_set = roundtrip(tag_set, set_data)
assert(out_set.Admin == true and out_set.Mod == true and out_set.Tester == true, "set mismatch")

-- literal

const lit_ping = ty.literal("ping")
assert(roundtrip(lit_ping, "ping") == "ping", "literal string failed")

const lit_id = ty.literal(42)
assert(roundtrip(lit_id, 42) == 42, "literal number failed")

-- enum

const status_enum = ty.enum("Idle, Walking, Running")
assert(roundtrip(status_enum, "Idle" :: "Idle") == "Idle", "enum Idle failed")
assert(roundtrip(status_enum, "Running" :: "Running") == "Running", "enum Running failed")

-- tagged union

const tagged_variant = ty.tagged({
	attack = {
		damage = ty.u16,
		critical = ty.boolean,
	},
	heal = {
		amount = ty.u16,
	},
	idle = {},
})
const atk_val = { type = "attack" :: "attack", damage = 150, critical = true }
const out_atk = roundtrip(tagged_variant, atk_val)
assert(out_atk.type == "attack" and out_atk.damage == 150 and out_atk.critical == true, "tagged attack mismatch")

const heal_val = { type = "heal" :: "heal", amount = 80 }
const out_heal = roundtrip(tagged_variant, heal_val)
assert(out_heal.type == "heal" and out_heal.amount == 80, "tagged heal mismatch")

const idle_val = { type = "idle" :: "idle" }
const out_idle = roundtrip(tagged_variant, idle_val)
assert(out_idle.type == "idle", "tagged idle mismatch")

-- union

const str_or_num = ty.union(ty.string, ty.optional(ty.u32))
assert(roundtrip(str_or_num, "hello") == "hello", "union variant 1 (string) failed")
assert(roundtrip(str_or_num, 12345) == 12345, "union variant 2 (u32) failed")
assert(roundtrip(str_or_num, nil) == nil, "union variant 2 (nil) failed")

const unknown_or_str_or_num = ty.union(ty.unknown, str_or_num)
assert(roundtrip(unknown_or_str_or_num, true) == true, "unknown_or_str_or_num variant 1 (unknown) failed")
assert(roundtrip(unknown_or_str_or_num, "hello") == "hello", "unknown_or_str_or_num variant 2 (string) failed")
assert(roundtrip(unknown_or_str_or_num, 12345) == 12345, "unknown_or_str_or_num variant 2 (12345) failed")
assert(roundtrip(unknown_or_str_or_num, nil) == nil, "unknown_or_str_or_num variant 2 (nil) failed")

-- intersect

const base_entity = ty.struct({
	id = ty.u32,
	name = ty.string,
})
const stats_entity = ty.struct({
	hp = ty.u16,
	shield = ty.u8,
})
const merged_entity = ty.intersect(base_entity, stats_entity)
const entity_data = {
	id = 77,
	name = "Warrior",
	hp = 500,
	shield = 100,
}
const out_entity = roundtrip(merged_entity, entity_data)
assert(out_entity.id == 77 and out_entity.name == "Warrior" and out_entity.hp == 500 and out_entity.shield == 100, "intersect mismatch")

-- refine

const bounded_u8 = ty.refine(ty.u8)(function(v)
	return v <= 100, `Expected u8 length to be less than or equal to 100, length is {v}`
end)
assert(roundtrip(bounded_u8, 50) == 50, "refine pass failed")
const refine_failed = not pcall(function()
	roundtrip(bounded_u8, 200)
end)
assert(refine_failed, "refine invalid rejected assertion failed")

-- custom type

const point2d = ty.create({
	type = "table",
	write = function(buff, offset, value)
		buffer.writei16(buff, offset, value.x)
		buffer.writei16(buff, offset + 2, value.y)
		return 4
	end,
	read = function(buff, offset)
		return 4, {
			x = buffer.readi16(buff, offset),
			y = buffer.readi16(buff, offset + 2),
		}
	end,
	size = 4,
})
const pt = { x = -150, y = 300 }
const out_pt = roundtrip(point2d, pt)
assert(out_pt.x == -150 and out_pt.y == 300, "custom create point2d mismatch")

-- tuples

const tuple2 = ty.tuple(ty.string, ty.u32)
const t2_str, t2_num = roundtrip_tuple(tuple2, "Hello", 99999)
assert(t2_str == "Hello" and t2_num == 99999, "tuple2 failed")

const tuple3 = ty.tuple(ty.u16, ty.optional(ty.string), ty.boolean)
const t3_n, t3_s, t3_b = roundtrip_tuple(tuple3, 42, "present", true)
assert(t3_n == 42 and t3_s == "present" and t3_b == true, "tuple3 with present optional failed")

const t3_n2, t3_s2, t3_b2 = roundtrip_tuple(tuple3, 99, nil, false)
assert(t3_n2 == 99 and t3_s2 == nil and t3_b2 == false, "tuple3 with nil optional failed")

const tuple4 = ty.tuple(ty.u8, ty.string, ty.boolean, ty.vec3)
const in_v3 = Vector3.new(1.5, 2.5, 3.5)
const t4_u8, t4_str, t4_bool, t4_vec = roundtrip_tuple(tuple4, 250, "Pact Tuple", true, in_v3)
assert(
	t4_u8 == 250 and t4_str == "Pact Tuple" and t4_bool == true and approx(t4_vec.X, in_v3.X) and approx(t4_vec.Y, in_v3.Y) and approx(t4_vec.Z, in_v3.Z),
	"tuple4 failed"
)

const tuple5 = ty.tuple(ty.u8, ty.string, ty.u16, ty.string, ty.boolean)
const a, b, c, d, e = roundtrip_tuple(tuple5, 1, "first", 2, "second", true)
assert(a == 1 and b == "first" and c == 2 and d == "second" and e == true, "tuple5 failed")

print("All datatypes tests passed successfully!")
