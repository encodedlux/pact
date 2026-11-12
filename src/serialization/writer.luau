export type Writer = {
	size: number,
	cursor: number,
	buff: buffer,
	refs: { any },
}

const function create(size: number?): Writer
	const size = size or 256
	return { size = size, cursor = 0, buff = buffer.create(size), refs = {} }
end

const function ensure(w: Writer, bytes: number)
	const required = w.cursor + bytes
	if required <= w.size then
		return
	end
	local new_size = w.size
	while new_size < required do
		new_size *= 2
	end
	const new_buff = buffer.create(new_size)
	buffer.copy(new_buff, 0, w.buff, 0, w.cursor)
	w.buff = new_buff
	w.size = new_size
end

const function write_many(
	players: { Player },
	writers: { [Player]: Writer },
	write: (Writer, ...any) -> (),
	exclude: Player?,
	...
)
	local serialized_buff: buffer
	local serialized_offset: number
	local serialized_bytes: number
	local source_refs: { any }
	local refs_start: number
	local refs_count: number = 0
	local is_serialized = false

	for _, player in players do
		if player == exclude then
			continue
		end
		const w = writers[player]
		if not w then
			continue
		end

		if is_serialized then
			ensure(w, serialized_bytes)
			const target_offset = w.cursor
			buffer.copy(w.buff, target_offset, serialized_buff, serialized_offset, serialized_bytes)
			w.cursor += serialized_bytes
			if refs_count > 0 then
				table.move(source_refs, refs_start, refs_start + refs_count - 1, #w.refs + 1, w.refs)
			end
		else
			const start_cursor = w.cursor
			const start_refs_count = #w.refs
			write(w, ...)
			serialized_buff = w.buff
			serialized_offset = start_cursor
			serialized_bytes = w.cursor - start_cursor
			source_refs = w.refs
			refs_start = start_refs_count + 1
			refs_count = #w.refs - start_refs_count
			is_serialized = true
		end
	end
end

return {
	create = create,
	ensure = ensure,
	write_many = write_many,
}
