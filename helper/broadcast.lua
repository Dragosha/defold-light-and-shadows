local M = {}

local receivers = {}

local function ensure_hash(string_or_hash)
	return type(string_or_hash) == "string" and hash(string_or_hash) or string_or_hash
end

local function url_to_key(url)
	return hash_to_hex(url.socket) .. hash_to_hex(url.path) .. hash_to_hex(url.fragment or hash(""))
end

--- Send a message to all registered receivers
-- @param message_id
-- @param message
function M.send(message_id, message)
	assert(message_id)
	local key = ensure_hash(message_id)
	if receivers[key] then
		message = message or {}
		for _,receiver in pairs(receivers[key]) do
			msg.post(receiver.url, message_id, message)
		end
	end
end

--- Register the current script as a receiver for a specific message
-- @param message_id
-- @param on_message_handler Optional message handler function to call
-- when a message is received. The function will receive the message
-- and sender as it's arguments. You must call @{on_message} for this
-- to work
function M.register(message_id, on_message_handler)
	assert(message_id)
	local url = msg.url()
	local key = ensure_hash(message_id)
	receivers[key] = receivers[key] or {}
	receivers[key][url_to_key(url)] = { url = url, handler = on_message_handler }
	-- pprint(receivers)
end

--- Unregister the current script from receiving a previously registered message
-- @param message_id
function M.unregister(message_id)
	assert(message_id)
	local key = ensure_hash(message_id)
	if receivers[key] then
		receivers[key][url_to_key(msg.url())] = nil
	end
end

---Unregister all their keys for the current script
function M.unregister_all()
	local url = url_to_key(msg.url())
	for _, key_receivers in pairs(receivers) do
		key_receivers[url] = nil
	end
end

--- Forward received messages in scripts where the broadcast module is used and where
-- registered messages have also provide a message handler function. If no message
-- handler functions are used then there is no need to call this function.
-- @param message_id
-- @param message
-- @param sender
-- @return true if the message was handled
function M.on_message(message_id, message, sender)
	local message_receivers = receivers[message_id]
	if not message_receivers then
		return false
	end

	local url = msg.url()
	for _,message_receiver in pairs(receivers[message_id]) do
		if message_receiver.url == url and message_receiver.handler then
			message_receiver.handler(message, sender)
			return true
		end
	end
	return false
end


return setmetatable(M, {
	__call = function(self, ...)
		return M.send(...)
	end
})
