# Scopes
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

## Usage

```luau
const net_server = net.server

net_server.example_scope.my_event.fire_all("Hello World")
```