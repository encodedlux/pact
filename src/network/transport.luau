--!native
--!optimize 2

const HttpService = game:GetService("HttpService")
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")

const constants = require("../constants")
const writer = require("../serialization/writer")

type Writer = writer.Writer

export type Transport = {
	reads: { (...any) -> (number, ...any) },
	dispatches: { (...any) -> () },
	player_writers: { [Player]: Writer },
	out_writer: Writer,
	unreliable_remote: UnreliableRemoteEvent,
	write_unreliable: (write_event: (w: Writer, ...any) -> (), ...any) -> (buffer, { [any]: any }?),
	flush: (() -> ())?,
}

const IS_SERVER = RunService:IsServer()

const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME
const ROOT_SCRIPT = constants.ROOT_SCRIPT
const FOLDER_NAME = ROOT_SCOPE_NAME .. "Remotes"
const EMPTY_REFS = { cursor = 0 }

const function get_root_folder(parent: Instance): Instance
	if not IS_SERVER then
		return parent:WaitForChild(FOLDER_NAME)
	end
	const found = parent:FindFirstChild(FOLDER_NAME)
	if found then
		return found
	end
	const made = Instance.new("Folder")
	made.Name = FOLDER_NAME
	made.Parent = parent
	return made
end

const function get_remote_names(name: string)
	const rel_attribute = name .. "_rel"
	const unrel_attribute = name .. "_unrel"

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

const function get_remotes(name: string)
	const rel_name, unrel_name = get_remote_names(name)
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
	const reliable_remote, unreliable_remote = get_remotes(namespace)

	const reads = table.create<<(...any) -> (number, ...any)>>(256)
	const dispatches = table.create<<(...any) -> ()>>(256)

	local player_writers: { [Player]: Writer }
	const out_writer = writer.create()
	const unreliable_writer = writer.create()

	local flush

	const function run_dispatch(id: number, player: Player?, bytes: number, ...)
		if player then
			dispatches[id](player, ...)
		else
			dispatches[id](...)
		end
		return bytes
	end

	const function on_incoming(player: Player?, buff: buffer, refs: { [any]: any }?)
		if type(buff) ~= "buffer" then
			return
		end
		if type(refs) == "table" then
			refs.cursor = 0
		else
			refs = EMPTY_REFS
		end
		const size = buffer.len(buff)
		local offset = 0
		while offset < size do
			const id = buffer.readu8(buff, offset)
			offset += 1
			const read = reads[id]
			if read then
				offset += run_dispatch(id, player, read(buff, offset, refs))
			else
				error(`Unknown event ID: {id}`)
			end
		end
	end

	const function write_unreliable(write_event, ...)
		unreliable_writer.cursor = 0
		table.clear(unreliable_writer.refs)
		write_event(unreliable_writer, ...)
		const cursor = unreliable_writer.cursor
		local buff = unreliable_writer.buff
		if cursor ~= unreliable_writer.size then
			buff = buffer.create(cursor)
			buffer.copy(buff, 0, unreliable_writer.buff, 0, cursor)
		end
		const has_refs = #unreliable_writer.refs > 0
		return buff, if has_refs then table.clone(unreliable_writer.refs) else nil
	end

	if IS_SERVER then
		player_writers = {}

		const function on_player_added(player: Player)
			player_writers[player] = writer.create()
		end

		Players.PlayerAdded:Connect(on_player_added)
		Players.PlayerRemoving:Connect(function(player)
			player_writers[player] = nil
		end)

		for _, player in Players:GetPlayers() do
			on_player_added(player)
		end

		flush = function()
			const cursor = out_writer.cursor
			if cursor > 0 then
				const refs = out_writer.refs
				const has_refs = #refs > 0
				const buff = buffer.create(cursor)
				buffer.copy(buff, 0, out_writer.buff, 0, cursor)
				reliable_remote:FireAllClients(buff, if has_refs then refs else nil)
				out_writer.cursor = 0
				if has_refs then
					table.clear(refs)
				end
			end
			for player, w in player_writers do
				const cursor = w.cursor
				if cursor > 0 then
					const refs = w.refs
					const has_refs = #refs > 0
					const buff = buffer.create(cursor)
					buffer.copy(buff, 0, w.buff, 0, cursor)
					reliable_remote:FireClient(player, buff, if has_refs then refs else nil)
					w.cursor = 0
					if has_refs then
						table.clear(refs)
					end
				end
			end
		end

		reliable_remote.OnServerEvent:Connect(on_incoming)
		unreliable_remote.OnServerEvent:Connect(on_incoming)
	else
		flush = function()
			const cursor = out_writer.cursor
			if cursor > 0 then
				const refs = out_writer.refs
				const has_refs = #refs > 0
				const buff = buffer.create(cursor)
				buffer.copy(buff, 0, out_writer.buff, 0, cursor)
				reliable_remote:FireServer(buff, if has_refs then refs else nil)
				out_writer.cursor = 0
				if has_refs then
					table.clear(refs)
				end
			end
		end

		const function on_incoming_client(buff: buffer, refs: { [any]: any }?)
			on_incoming(nil, buff, refs)
		end
		reliable_remote.OnClientEvent:Connect(on_incoming_client)
		unreliable_remote.OnClientEvent:Connect(on_incoming_client)
	end

	if auto_flush ~= false then
		RunService.PostSimulation:Connect(flush)
	end

	return {
		reads = reads,
		dispatches = dispatches,
		player_writers = player_writers,
		out_writer = out_writer,
		unreliable_remote = unreliable_remote,
		write_unreliable = write_unreliable,
		flush = if auto_flush == false then flush else nil,
	}
end

return transport
