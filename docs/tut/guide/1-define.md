# Getting Started

## Creating a definition
Start by creating a shared module that contains the networking definitions used by your game.

Pact lets you define objects in one place, with their data types described explicitly.

```luau
-- net.luau
const define = pact.define
const event = pact.event
const t = pact.t

return define("game", {
	my_event = event({
		from = "Server",
		type = "Reliable",
		call = "Async",
		value = t.string,
	}),
})
```

## Accessing the definition

A definition exposes `.server` and `.client`:

```luau
const net = require(path.to.net)

const net_server = net.server -- for server-side only
const net_client = net.client -- for client-side only
```

Both return the same network definition, with the appropriate interface for each environment.

This allows the same definition to be shared between server and client code without maintaining separate network declarations.

## Options

### `casing`
Controls the naming convention used by the generated API.

Default: `snake_case`
Options: `snake_case`, `camelCase`, `PascalCase`

```luau
return define("game", {
	...
}, {
    casing = "camelCase",
})
```

### `default_call`
Call mode assumed by any event that doesn't declare its own `call`.

Default: `Async`
Options: `Async`, `Sync`, `Polling`

### `auto_flush`
Reliable events, functions, and state changes are combined into a single delivery once per frame (flushed automatically during `RunService.PostSimulation`). Unreliable events are fired immediately.

When set to `false`, automatic frame flushing is disabled and you become responsible for calling `flush()` — exposed on both `.server` and `.client`.

Default: `true`

Server:
```luau
RunService.PostSimulation:Connect(net_server.flush) -- delivers queued reliable events, functs, and states manually
```
Client:
```luau
RunService.PostSimulation:Connect(net_client.flush) -- delivers queued reliable events, functs, and states manually
```

## Scopes
Scopes nest related objects under a shared table, both in the definition file and in the resulting API.

```luau
return define("game", {
	example_scope = {
		my_event = event({
			value = t.string,
		}),
	},
})
```

### Usage

```luau
const net_server = net.server

net_server.example_scope.my_event.fire_all("Hello World")
```