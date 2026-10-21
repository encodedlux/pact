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
	local thread = table.remove(free_threads) :: thread
	if not thread then
		thread = coroutine.create(yielder)
		coroutine.resume(thread)
	end
	task.spawn(thread, f, thread, ...)
end

const function spawn_callbacks<T...>(callbacks: { (T...) -> () }, ...: T...)
	for i = 1, #callbacks do
		local thread = table.remove(free_threads) :: thread
		if not thread then
			thread = coroutine.create(yielder)
			coroutine.resume(thread)
		end
		task.spawn(thread, callbacks[i], thread, ...)
	end
end

return {
	spawn = spawn,
	spawn_callbacks = spawn_callbacks,
}
