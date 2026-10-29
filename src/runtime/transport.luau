--!native
--!optimize 2

const HttpService = game:GetService("HttpService")
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")

const constants = require("../constants")
const serdes = require("./serdes")
const t = require("../types")

type BufferSave = t.BufferSave
type DataType = t.DataType

export type Transport = {
	read_fns: { (...any) -> (number, ...any) },
	dispatches: { (...any) -> () },
	client_reliable: BufferSave,
	client_unreliable: BufferSave,
	players_reliable: { [Player]: BufferSave },
	players_unreliable: { [Player]: BufferSave },
	flush: (() -> ())?,
}

const IS_SERVER = RunService:IsServer()
const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME
const ROOT_SCRIPT = constants.ROOT_SCRIPT
const EMPTY_REFS = { cursor = 0 }

const create_save = serdes.create_save

const readu8 = buffer.readu8
const buffer_create, buffer_copy, buffer_len = buffer.create, buffer.copy, buffer.len

const function get_root_folder(parent: Instance): Instance
	const folder_name = ROOT_SCOPE_NAME .. "Remotes"

	if not IS_SERVER then
		return parent:WaitForChild(folder_name)
	end
	const found = parent:FindFirstChild(folder_name)
	if found then
		return found
	end

	const made = Instance.new("Folder")
	made.Name = folder_name
	made.Parent = parent
	return made
end

const function get_remote_names(namespace: string)
	const rel_attribute = namespace .. "_rel"
	const unrel_attribute = namespace .. "_unrel"

	local rel_name: string
	local unrel_name: string

	if IS_SERVER then
		rel_name = HttpService:GenerateGUID(false)
		unrel_name = HttpService:GenerateGUID(false)
		ROOT_SCRIPT:SetAttribute(rel_attribute, rel_name)
		ROOT_SCRIPT:SetAttribute(unrel_attribute, unrel_name)
	else
		rel_name = ROOT_SCRIPT:GetAttribute(rel_attribute) :: string
		if not rel_name then
			ROOT_SCRIPT:GetAttributeChangedSignal(rel_attribute):Wait()
			rel_name = ROOT_SCRIPT:GetAttribute(rel_attribute) :: string
		end
		unrel_name = ROOT_SCRIPT:GetAttribute(unrel_attribute) :: string
		if not unrel_name then
			ROOT_SCRIPT:GetAttributeChangedSignal(unrel_attribute):Wait()
			unrel_name = ROOT_SCRIPT:GetAttribute(unrel_attribute) :: string
		end
	end

	return rel_name, unrel_name
end

const function setup_remotes(namespace: string)
	const rel_name, unrel_name = get_remote_names(namespace)
	const root = get_root_folder(ReplicatedStorage)

	local reliable: RemoteEvent
	local unreliable: UnreliableRemoteEvent

	if IS_SERVER then
		reliable = root:FindFirstChild(rel_name) :: RemoteEvent
		if not reliable then
			reliable = Instance.new("RemoteEvent")
			reliable.Name = rel_name
			reliable.Parent = root
		end

		unreliable = root:FindFirstChild(unrel_name) :: UnreliableRemoteEvent
		if not unreliable then
			unreliable = Instance.new("UnreliableRemoteEvent")
			unreliable.Name = unrel_name
			unreliable.Parent = root
		end
	else
		reliable = root:WaitForChild(rel_name) :: RemoteEvent
		unreliable = root:WaitForChild(unrel_name) :: UnreliableRemoteEvent
	end

	return reliable, unreliable
end

const function transport(namespace: string, auto_flush: boolean?): Transport
	const reliable_remote, unreliable_remote = setup_remotes(namespace)

	const event_read_fns = table.create<<(...any) -> (number, ...any)>>(256)
	const event_dispatches = table.create<<(...any) -> ()>>(256)

	local players_reliable: { [Player]: BufferSave }
	local players_unreliable: { [Player]: BufferSave }
	local client_reliable: BufferSave
	local client_unreliable: BufferSave

	local flush

	local serdes_thread: thread?

	const function run_dispatch(id: number, player: Player?, bytes: number, ...)
		if player then
			event_dispatches[id](player, ...)
		else
			event_dispatches[id](...)
		end
		return bytes
	end

	const function on_incoming(player: Player?, buff: buffer, refs: { [any]: any }?)
		if refs then
			refs.cursor = 0
		else
			refs = EMPTY_REFS
		end
		const size = buffer_len(buff)
		local offset = 0
		if serdes_thread and coroutine.status(serdes_thread) == "suspended" then
			warn(
				`[{ROOT_SCOPE_NAME}]: Yielded in a Sync call. An Event uses a Sync call, consider using an Async call instead.`
			)
			coroutine.close(serdes_thread)
		end
		serdes_thread = coroutine.running()
		while offset < size do
			const id = readu8(buff, offset)
			offset += 1
			const read_fn = event_read_fns[id]
			if not read_fn then
				warn(`[{ROOT_SCOPE_NAME}]: Unknown event ID {id} received.`)
				break
			end
			offset += run_dispatch(id, player, read_fn(buff, offset, refs))
		end
	end

	if IS_SERVER then
		players_reliable = {}
		players_unreliable = {}

		const function on_player_added(player: Player)
			players_reliable[player] = create_save()
			players_unreliable[player] = create_save()
		end

		Players.PlayerAdded:Connect(on_player_added)
		Players.PlayerRemoving:Connect(function(player)
			players_reliable[player] = nil
			players_unreliable[player] = nil
		end)

		for _, player in Players:GetPlayers() do
			on_player_added(player)
		end

		flush = function()
			for player, save in players_unreliable do
				if save.cursor > 0 then
					const has_refs = #save.refs > 0
					const size = save.cursor
					const buff = buffer_create(size)
					buffer_copy(buff, 0, save.buff, 0, size)
					unreliable_remote:FireClient(player, buff, has_refs and save.refs or nil)
					save.cursor = 0
					if has_refs then
						table.clear(save.refs)
					end
				end
			end
			for player, save in players_reliable do
				if save.cursor > 0 then
					const has_refs = #save.refs > 0
					const size = save.cursor
					const buff = buffer_create(size)
					buffer_copy(buff, 0, save.buff, 0, size)
					reliable_remote:FireClient(player, buff, has_refs and save.refs or nil)
					save.cursor = 0
					if has_refs then
						table.clear(save.refs)
					end
				end
			end
		end

		reliable_remote.OnServerEvent:Connect(on_incoming)
		unreliable_remote.OnServerEvent:Connect(on_incoming)
	else
		client_reliable = create_save()
		client_unreliable = create_save()

		flush = function()
			if client_unreliable.cursor > 0 then
				const has_refs = #client_unreliable.refs > 0
				const size = client_unreliable.cursor
				const buff = buffer_create(size)
				buffer_copy(buff, 0, client_unreliable.buff, 0, size)
				unreliable_remote:FireServer(buff, has_refs and client_unreliable.refs or nil)
				client_unreliable.cursor = 0
				if has_refs then
					table.clear(client_unreliable.refs)
				end
			end
			if client_reliable.cursor > 0 then
				const has_refs = #client_reliable.refs > 0
				const size = client_reliable.cursor
				const buff = buffer_create(size)
				buffer_copy(buff, 0, client_reliable.buff, 0, size)
				reliable_remote:FireServer(buff, has_refs and client_reliable.refs or nil)
				client_reliable.cursor = 0
				if has_refs then
					table.clear(client_reliable.refs)
				end
			end
		end

		const function relay(buff: buffer, refs: { [any]: any }?)
			on_incoming(nil, buff, refs)
		end
		reliable_remote.OnClientEvent:Connect(relay)
		unreliable_remote.OnClientEvent:Connect(relay)
	end

	if auto_flush ~= false then
		RunService.PostSimulation:Connect(flush)
	end

	return {
		read_fns = event_read_fns,
		dispatches = event_dispatches,
		players_reliable = players_reliable,
		players_unreliable = players_unreliable,
		client_reliable = client_reliable,
		client_unreliable = client_unreliable,
		flush = if auto_flush == false then flush else nil,
	}
end

return transport
