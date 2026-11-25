--!native
--!optimize 2

local free_threads: { thread } = {}

const function run(f: (...any) -> (), thread: thread, ...)
	f(...)
	table.insert(free_threads, thread)
end

const function yielder()
	while true do
		run(coroutine.yield())
	end
end

const function spawn<T...>(f: (T...) -> (), ...: T...)
	local thread
	const len = #free_threads
	if len > 0 then
		thread = free_threads[len]
		free_threads[len] = nil
	else
		thread = coroutine.create(yielder)
		coroutine.resume(thread)
	end
	task.spawn(thread, f, thread, ...)
end

const function spawn_callbacks<T...>(callbacks: { (T...) -> () }, ...: T...)
	for _, f in callbacks do
		local thread
		const len = #free_threads
		if len > 0 then
			thread = free_threads[len]
			free_threads[len] = nil
		else
			thread = coroutine.create(yielder)
			coroutine.resume(thread)
		end
		task.spawn(thread, f, thread, ...)
	end
end

return {
	spawn = spawn,
	spawn_callbacks = spawn_callbacks,
}
