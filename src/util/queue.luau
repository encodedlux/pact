--!native
--!optimize 2

export type Queue = {
	size: number,
	width: number,
	cursor: number,
	data: { any },
}

const function create(width: number): Queue
	return { size = 0, width = width, cursor = 0, data = {} }
end

const function push(queue: Queue, ...)
	const data = queue.data
	const base = queue.size * queue.width
	queue.size += 1
	for i = 1, queue.width do
		data[base + i] = select(i, ...)
	end
end

const function from_offset(queue: Queue, offset: number)
	const width = queue.width
	const base = (offset - 1) * width
	return table.unpack(queue.data, base + 1, base + width)
end

const function clear(queue: Queue)
	queue.size = 0
	queue.cursor = 0
	table.clear(queue.data)
end

return {
	create = create,
	push = push,
	from_offset = from_offset,
	clear = clear,
}
