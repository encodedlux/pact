# Types

This page contains an explanation of all DataTypes supported by Pact.

---

# Primitives

Pact provides a collection of primitive types that serve as the foundation for creating more complex data types tailored to your game.

## General types

- `string`: string
- `boolean`: boolean
- `buffer`: buffer
- `unknown`: any
- `none`: nil
- `vec`: vector

## Number types

- `u8`: Unsigned 8-bit integer
- `u16`: Unsigned 16-bit integer
- `u32`: Unsigned 32-bit integer
- `i8`: Signed 8-bit integer
- `i16`: Signed 16-bit integer
- `i32`: Signed 32-bit integer
- `f16`: 16-bit float
- `f32`: 32-bit float
- `f64`: 64-bit float

## Roblox types

- `vec2`: Vector2
- `vec3`: Vector3
- `cframe`: CFrame
- `instance`: Instance
- `color3`: Color3
- `player`: Player

---

# Special

Special types are used to build more complex structures. They can contain nearly any type, including other special types, and are designed to be dynamic.

## Optionals

Optionals wrap an existing datatype to allow it to be `nil` (`T?` type). Uses 1 byte of overhead for each optional value.

```luau
-- net.luau
return define("example", {
    my_event = event({
        value = t.optional(t.string)
    })
})
```
```luau
-- server.luau
net_server.my_event.fire_all("hello")
net_server.my_event.fire_all(nil)
```

## Literal

Literal defines a single constant value.

```luau
-- net.luau
return define("example", {
    my_event = event({
        value = t.literal("ping")
    })
})
```
```luau
-- server.luau
net_server.my_event.fire_all("ping")
```

## Enum

Enum defines a set of string options separated by a comma and a space (`", "`). It uses 1 byte over the wire.

```luau
-- net.luau
return define("example", {
    my_event = event({
        value = t.enum("Red, Green, Blue")
    })
})
```

In this example, the value can only be `"Red"`, `"Green"`, or `"Blue"`:
```luau
-- server.luau
net_server.my_event.fire_all("Red")
net_server.my_event.fire_all("Green")
```

## Arrays

Arrays are straightforward: they represent ordinary ordered arrays. One thing to keep in mind is that passing mixed tables as arrays has **undefined** behavior. As a result, some values may not be preserved when the data is received.

Arrays use 2 bytes of overhead. These bytes store the array length as an `u16`. Because of this, arrays can contain up to **65,536** entries.

```luau
-- net.luau
return define("example", {
    my_event = event({
        value = t.array(t.string)
    })
})
```
```luau
-- server.luau
net_server.my_event.fire_all({ "foo", "bar" })
```

## Sets

Sets represent a collection of unique values, where each value acts as a member of the set. Unlike an array, a set does not care about element order or numeric indices.

```luau
-- net.luau
return define("example", {
    my_event = event({
        value = t.set(t.string)
    })
})
```
```luau
-- server.luau
net_server.my_event.fire_all({
    ["foo"] = true,
    ["bar"] = true,
})
```

## Maps

Maps are used to store values using keys. Both the key and value can have their own datatype, allowing you to define maps with different key and value types.

```luau
-- net.luau
return define("example", {
    my_event = event({
        value = t.map(t.string, t.boolean)
    })
})
```
```luau
-- server.luau
net_server.my_event.fire_all({
    ["foo"] = true,
    ["bar"] = false,
})
```

## Structs

Structs are used to group multiple named values into a single structured type. Each field can have its own datatype, allowing you to define the exact shape of the data being sent.

```luau
-- net.luau
return define("example", {
    my_event = event({
        value = t.struct({
            foo = t.string,
            bar = t.u8
        })
    })
})
```
```luau
-- server.luau
net_server.my_event.fire_all({
    foo = "foo",
    bar = 2,
})
```

## Tagged

Tagged defines a value that can have different data structures depending on a specified tag. Each tag represents a variant with its own schema, allowing different fields and data types for each variant.

```luau
-- net.luau
return define("example", {
    my_event = event({
        value = t.tagged({
            foo = {
                value = t.string
            },
            bar = {
                x = t.f32,
                y = t.f32,
                z = t.f32
            }
        })
    })
})
```
```luau
-- server.luau
net_server.my_event.fire_all({
    type = "foo",
    value = "hello world"
})

net_server.my_event.fire_all({
    type = "bar",
    x = 0,
    y = 1,
    z = 2
})
```

## Union

Unions allow a value to match one of multiple types. They use 1 byte of overhead.

```luau
-- net.luau
return define("example", {
    my_event = event({
        value = t.union(t.string, t.u32, t.boolean)
    })
})
```
```luau
-- server.luau
net_server.my_event.fire_all("admin") -- matches string
net_server.my_event.fire_all(100)     -- matches number
net_server.my_event.fire_all(true)    -- matches boolean
```

## Intersect

Intersect combines multiple structured table datatypes into a single compound schema.
When deserialized, fields from all variants are merged into a single table.

```luau
-- net.luau
const base_entity = t.struct({
    id = t.u32,
    position = t.vec3,
})

const health = t.struct({
    hp = t.u16,
    max_hp = t.u16,
})

return define("example", {
    spawn_entity = event({
        value = t.intersect(base_entity, health)
    })
})
```
```luau
-- server.luau
net_server.spawn_entity.fire_all({
    id = 1,
    position = Vector3.new(0, 10, 0),
    hp = 100,
    max_hp = 100,
})
```

::: warning
If a key exists in multiple variants of an intersect, the later variant overwrites the value from earlier variants and emits a runtime warning.
:::

## Tuples

Tuples let a single event or funct carry more than one value.

```luau
-- net.luau
return define("example", {
    my_event = event({
        value = t.tuple(t.string, t.u8, t.optional(t.vec2))
    })
})
```
```luau
-- server.luau
net_server.my_event.fire_all("hello world", 2, Vector2.new(1, 1))
net_server.my_event.fire_all("hello world", 2)
```

## Custom

Custom types let you create a datatype with a custom wire representation when the built-in datatypes cannot express the desired encoding efficiently.

```luau
type WeaponData = {
    level: number,
    model: Model?
}

const weapon = t.create<<WeaponData>>({
    type = "table",
    write = function(buff, offset, value, refs)
        buffer.writeu16(buff, offset, value.level)
        t.push_ref(refs, value.model)

        return 2
    end,
    read = function(buff, offset, refs)
        const level = buffer.readu16(buff, offset)
        const model = t.next_ref(refs)

        return 2, {
            level = level,
            model = model,
        }
    end,
    size = 2,
})
```

### Definition Fields

| Field | Description |
| :--- | :--- |
| `type` | The value typeof (e.g. "table", "number", "string") |
| `write` | Writes `value` to `buff` at `offset`. Returns bytes written. |
| `read` | Reads binary data at `offset`. Returns bytes read and deserialized value. |
| `size` | Exact number of bytes required by the datatype. Fixed number or sizing function. |

### Dynamic Sizing

For variable-sized types (e.g., dynamic strings or variable payloads), `size` must be a function:

```luau
export type PlayerProfile = {
    level: number,
    name: string,
}

const profile = t.create<<PlayerProfile>>({
    type = "table",
    write = function(buff, offset, value, refs)
        buffer.writeu16(buff, offset, value.level)

        const name_len = string.len(value.name)
        buffer.writeu8(buff, offset + 2, name_len)
        buffer.writestring(buff, offset + 3, value.name)

        return 3 + name_len
    end,
    read = function(buff, offset, refs)
        const level = buffer.readu16(buff, offset)

        const name_len = buffer.readu8(buff, offset + 2)
        const name = buffer.readstring(buff, offset + 3, name_len)

        return 3 + name_len, {
            level = level,
            name = name,
        }
    end,
    size = function(value)
        return 3 + string.len(value.name)
    end,
})
```

The `size` function is used to pre-calculate required buffer capacities before writing. It must always return the exact byte count that `write` will produce.

### References

`refs` is a reference array transmitted alongside the binary buffer. It is used to pass Roblox instances, unknowns, and non-bufferable objects without polluting binary offsets.

References do not consume buffer space. Instead, they are passed as secondary arguments in Roblox remotes.

`t` provides helper functions to handle references safely:

1. **Writing**: Use `t.push_ref(refs, value)` to append values. It automatically handles `nil` safely.
   ```luau
   t.push_ref(refs, value.model)
   ```
2. **Reading**: Use `t.next_ref(refs)` to retrieve values in the order they were inserted.
   ```luau
   const model = t.next_ref(refs)
   ```

```luau
-- Writer inserting multiple references:
function(buff, offset, value, refs)
    t.push_ref(refs, value.model)
    t.push_ref(refs, value.owner)
    t.push_ref(refs, value.target)
    return 0
end

-- Reader consuming references:
function(buff, offset, refs)
    const model = t.next_ref(refs)
    const owner = t.next_ref(refs)
    const target = t.next_ref(refs)

    return 0, {
        model = model,
        owner = owner,
        target = target,
    }
end
```

---

## Refine

`t.refine(value_type)(predicate_fn)`

Refine wraps an existing datatype and attaches custom validation rules. It ensures values conform to business constraints and safety invariants before reaching your listener callbacks.

### Usage

```luau
-- net.luau
const Health = t.refine(t.u8)(function(hp)
    return hp <= 100, "Health must not exceed 100"
end)

return define("game", {
    set_health = event({
        from = "Client",
        value = Health,
    }),
})
```
```luau
-- server.luau
net_server.set_health.on(function(player, hp)
    -- Guaranteed to be <= 100
    print(`{player.Name} health updated: {hp}`)
end)
```
