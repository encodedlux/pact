# States

States represent persistent values that can be read, updated, and observed by both the server and client.

## Defining a State

A state is created by calling `state`:
```luau
return define("game", {
    score = state({
        value = t.u32,
        initial = 0,
    }),
})
```

A state can also contain structured data. For example, a map can store data for each player:

```luau
return define("game", {
    accounts = state({
        value = t.map(
            t.player,
            t.struct({
                level = t.u16,
                coins = t.u32,
                pets = t.array(t.string),
            }),
        ),
        initial = {},
    }),
})
```

### `value`

Defines the type of data stored by the state.

```luau
value = t.u32
```

### `initial`

Defines the initial value of the state.

```luau
initial = 0
```

The initial value must match the type defined by `value`.

## Usage

### Updating

The server updates a state with `set()`:

```luau
net_server.score.set(100)
```

`set()` also accepts a callback that receives the current value and returns the new one:

```luau
net_server.accounts.set(function(state)
    const new_state = table.clone(state)
    new_state[player] = {
        level = 1,
        coins = 0,
    }
    return new_state
end)
```

This is useful when the next value depends on the current state:

```luau
const function add_coins(player: Player, amount: number)
    net_server.accounts.set(function(state)
        if state[player] == nil then
            return false
        end
        const new_state = table.clone(state)
        const new_account = table.clone(new_state[player])
        new_account.coins += amount
        new_state[player] = new_account
        return new_state
    end)
end
```

Returning `false` from the callback cancels the update.

### Client View

By default, every client receives the authoritative state stored on the server. Use `set_client_view()` to define a custom perspective or projection of the state for each client before replication.
The callback receives the target `Player` and the current state value, and returns the tailored state to be serialized and sent to that client.
The returned value must strictly match the schema format defined by `value`. Returning an incompatible structure or mismatched types is invalid and causes serialization errors.
This allows the server to customize the replicated state per player—such as adjusting data to a player's perspective, transforming values, or filtering out private information so clients only receive what they need to see.

For example, to filter data so each player only receives their own account:

```luau
net_server.accounts.set_client_view(function(player, accounts)
    return {
        [player] = accounts[player],
    } -- Exclude all other players' accounts
end)
```

Here, `accounts` is the complete state on the server. Notice that the returned table preserves the dictionary schema expected by `value` (`t.map(t.player, ...)`), delivering the customized view to that specific player.

### Subscribing to State

Use `on()` to run a callback when the state changes:

```luau
net_server.accounts.on(function(state, prev_state)
    for player in state do
        if prev_state[player] == nil then
            -- Account was added
        end
    end
end)
```

You can also subscribe to a value getter:

```luau
const function get_player_coins(player: Player)
    return function(state)
        return state[player].coins
    end
end

const get_coins = get_player_coins(player)

net_server.accounts.on(get_coins, function(coins, prev_coins)
    if prev_coins and coins > prev_coins then
        print(`{player.Name} gained {coins - prev_coins} coins!`)
    end
end)
```

The callback only runs when the returned value changes.

`on()` returns a cleanup function:

```luau
const disconnect = net_server.accounts.on(function(state)
    -- ...
end)

disconnect()
```

### Getting a Value

Use `get()` to read the current state value:

```luau
const value = net_server.score.get()

print(value)
```

You can also pass a value getter:

```luau
const function get_player_coins(player: Player)
    return function(state)
        return state[player].coins
    end
end

const get_coins = get_player_coins(player)
const coins = net_server.accounts.get(get_coins)
print(coins)
```

The state passes its current value to the value getter.

### Using Selectors

Use `selector()` to create a cached value selection for expensive or frequently reused transformations.

Consider calculating a leaderboard directly:

```luau
const function select_top_coins(state)
    -- This creates a new table every time the function is called
    const sorted = {}

    for player, data in state do
        table.insert(sorted, {
            player = player,
            coins = data.coins,
        })
    end

    table.sort(sorted, function(a, b)
        return a.coins > b.coins
    end)

    return sorted
end

const function display_top_coins()
    for rank, data in net_server.accounts.get(select_top_coins) do
        print(`Rank: {rank}, Player: {data.player.Name}, Coins: {data.coins}`)
    end
end

display_top_coins() -- creates a new table and sorts it
display_top_coins() -- creates a new table and sorts it - 2x
```

Every call to `select_top_coins()` creates a new table and sorts it again, even when `accounts` has not changed.

With `selector()`, the result is cached:

```luau
const select_top_coins = net_server.accounts.selector(function(state)
    const sorted = {}

    for player, data in state do
        table.insert(sorted, {
            player = player,
            coins = data.coins,
        })
    end

    table.sort(sorted, function(a, b)
        return a.coins > b.coins
    end)

    return sorted
end)

const function display_top_coins()
    for rank, data in net_server.accounts.get(select_top_coins) do
        print(`Rank: {rank}, Player: {data.player.Name}, Coins: {data.coins}`)
    end
end

display_top_coins() -- Computes the leaderboard
display_top_coins() -- Reuses the cached result
```

The selector value is recomputed when the state changes, or when the selector passed as the first argument changes.

```luau
const function select_player_coins(player: Player)
    return function(state)
        return state[player].coins
    end
end

const select_coins = select_player_coins(player)

const select_double_coins = net_server.accounts.selector(select_coins, function(coins)
    return coins * 2
end)
```
