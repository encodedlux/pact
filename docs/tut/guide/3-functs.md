# Functs
Functs are Pact's version of a `RemoteFunction`, allowing the client to request data or an operation from the server and receive a response.

The client calls `invoke(...)` and yields until the server's handler returns.

## Defining a Funct

A funct is created by calling `funct`:
```luau
return define("game", {
	get_balance = funct({
		value = t.none,
		ret = t.u32,
	}),
})
```

In this example, `get_balance` does not require any input and returns an unsigned 32-bit integer.

### `value`

Defines the data sent from the client to the server.

```luau
value = t.u8
```

The client can then pass a value when invoking the funct:

```luau
net_client.my_funct.invoke(5)
```

Use `t.tuple(...)` when the funct needs multiple input values:

```luau
value = t.tuple(t.string, t.u8)
```

When the funct does not require any input, `value` can be omitted or set to `t.none`.

### `ret`

Defines the data returned by the server.

```luau
ret = t.u32
```

The value returned by the server is received by the client:

```luau
const balance = net_client.get_balance.invoke()

print(balance)
```

Use `t.tuple(...)` when the server needs to return multiple values:

```luau
ret = t.tuple(
    t.u32,
    t.string
)
```

## Usage

### Invoking (client)
```luau
-- client.luau
const balance = net_client.get_balance.invoke()

print(`Balance: {balance}`)
```

The call yields until the server returns a value.

### Handling (server)
```luau
-- server.luau
net_server.get_balance.on(function(player)
    return player:GetAttribute("Balance") or 0
end)
```

The returned value is sent back to the client that invoked the funct.

### Passing Args

Functs can receive typed data from the client:

```luau
return define("game", {
    get_item_price = funct({
        value = t.string,
        ret = t.u32,
    }),
})
```

The client provides the item name:

```luau
const price = net_client.get_item_price.invoke("sword")

print(`Price: {price}`)
```

The server handles the request:

```luau
net_server.get_item_price.on(function(player, item_name)
    const item = items[item_name]
    if not item then
        return 0
    end
    return item.price
end)
```

This makes functs useful for request-and-response operations where the client needs a result from the server.