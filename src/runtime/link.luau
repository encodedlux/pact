--!native
--!optimize 2

const RunService = game:GetService("RunService")

const constants = require("../constants")
const queue = require("../util/queue")
const transport = require("./transport")

type Queue = queue.Queue

export type Link = {
	registered: { [string]: true },
	next_id: number,
	invocations_stack: buffer,
	invocations_top: number,
	invocations: { [number]: thread },
	transport: transport.Transport,
}

const IS_SERVER = RunService:IsServer()
const ROOT_SCRIPT = constants.ROOT_SCRIPT
const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME
const MAX_EVENT_IDS = 256

const function next_event_id(lnk: Link, name: string): number
	const attribute = name .. "_event_id"
	if IS_SERVER then
		const id = lnk.next_id
		if id >= MAX_EVENT_IDS then
			error(`[{ROOT_SCOPE_NAME}]: Max number of events reached.`)
		end
		lnk.next_id += 1
		ROOT_SCRIPT:SetAttribute(attribute, id)
		return id
	end

	local id = ROOT_SCRIPT:GetAttribute(attribute)
	if not id then
		ROOT_SCRIPT:GetAttributeChangedSignal(attribute):Wait()
		id = ROOT_SCRIPT:GetAttribute(attribute)
	end
	if not id then
		error(`[{ROOT_SCOPE_NAME}]: Unable to get event id for "{name}"`)
	end
	return id :: number
end

const function link_new(namespace: string, auto_flush: boolean?): Link
	local invocations_stack: buffer

	if not IS_SERVER then
		invocations_stack = buffer.create(256)
		for i = 0, 255 do
			buffer.writeu8(invocations_stack, i, i)
		end
	end

	return {
		registered = {} :: { [string]: true },
		next_id = 0,
		invocations_stack = invocations_stack,
		invocations_top = 256,
		invocations = {} :: { [number]: thread },
		transport = transport(namespace, auto_flush),
	}
end

return {
	new = link_new,
	next_event_id = next_event_id,
}
