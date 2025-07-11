local M = {}



local function resume(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if err then print(err) end
end

function M.run_once(fn, ...)
	coroutine.wrap(fn)(...)
end

function M.run_loop(fn, ...)
	coroutine.wrap(function(...)
		while true do
			fn(...)
		end
	end)(...)
end

function M.delay(seconds)
	local co = coroutine.running()
	assert(co, "You must call this from inside a sequence")
	timer.delay(seconds, false, function()
		resume(co)
	end)
	coroutine.yield()
end

function M.wait_until_false(fn)
	local co = coroutine.running()
	timer.delay(0, true, function(self, handle, time_elapsed)
		if not fn() then
			timer.cancel(handle)
			coroutine.resume(co)
		end
	end)
	coroutine.yield()
end

function M.wait_until_true(fn)
	local co = coroutine.running()
	timer.delay(0, true, function(self, handle, time_elapsed)
		if fn() then
			timer.cancel(handle)
			coroutine.resume(co)
		end
	end)
	coroutine.yield()
end

function M.gui_animate(node, property, to, easing, duration, delay, playback)
	local co = coroutine.running()
	assert(co, "You must call this from inside a sequence")
	gui.animate(node, property, to, easing, duration, delay, function()
		resume(co)
	end, playback)
	coroutine.yield()
end

function M.go_animate(url, property, playback, to, easing, duration, delay)
	local co = coroutine.running()
	assert(co, "You must call this from inside a sequence")
	delay = delay or 0
	if property == "position.xy" then
		go.animate(url, "position.x", playback, to.x, easing, duration, delay, nil)
		go.animate(url, "position.y", playback, to.y, easing, duration, delay, function()
			resume(co)
		end)
	else
		go.animate(url, property, playback, to, easing, duration, delay, function()
			resume(co)
		end)
	end
	coroutine.yield()
end

function M.spine_play_anim(url, anim_id, playback, play_properties)
	local co = coroutine.running()
	assert(co, "You must call this from inside a sequence")
	if spine then
		spine.play_anim(url, anim_id, playback, play_properties, function(self, message_id, message, sender)
			resume(co)
		end)
	end
	coroutine.yield()
end

function M.gui_play_flipbook(node, id)
	local co = coroutine.running()
	assert(co, "You must call this from inside a sequence")
	gui.play_flipbook(node, id, function()
		resume(co)
	end)
	coroutine.yield()
end

function M.sprite_play_flipbook(url, id)
	local co = coroutine.running()
	assert(co, "You must call this from inside a sequence")
	sprite.play_flipbook(url, id, function()
		resume(co)
	end)
	coroutine.yield()
end

function M.http_request(url, method, headers, post_data, options)
	local co = coroutine.running()
	assert(co, "You must call this from inside a sequence")
	
	http.request(url, method, function(self, id, response)
		resume(co, response)
	end,headers, post_data, options)
	return coroutine.yield()
end

function M.http_get(url, headers, options)
	return M.http_request(url, "GET", headers, nil, options)
end

function M.http_post(url, headers, post_data, options)
	return M.http_request(url, "POST", headers, post_data, options)
end

function M.call(fn, ...)
	local co = coroutine.running()
	assert(co, "You must call this from inside a sequence")
	local results = nil
	local yielded = false
	local done = false
	fn(function(...)
		done = true
		if yielded then
			resume(co, ...)
		else
			results = { ... }
		end
	end, ...)
	if not done then
		print("not done, yielding")
		yielded = true
		results = { coroutine.yield() }
	end
	return unpack(results)
end

return M
