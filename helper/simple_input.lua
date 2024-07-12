local M = {}

local registered_nodes = {}
M.registered_nodes = registered_nodes
local longtap={}

local function ensure_node(node_or_node_id)
    return type(node_or_node_id) == "string" and gui.get_node(node_or_node_id) or node_or_node_id
end

function M.set_alpha(node, alpha)
    local n = ensure_node(node)
    local color = gui.get_color(n)
    color.w = alpha
    gui.set_color(n, color)
end

--- Convenience function to acquire input focus
function M.acquire()
    msg.post("#", "acquire_input_focus")
end

--- Convenience function to release input focus
function M.release()
    msg.post("#", "release_input_focus")
end

--- Register a node and a callback to invoke when the node
-- receives input
function M.register(param, callback, value, click_cb, longtap_cb)
    assert(param, "You must provide a node")

    if type(param) == 'table' then
        local node = ensure_node(param.node)
        registered_nodes[node] = { url = msg.url(), callback = param.callback, click_cb=param.click_cb, node = node, scale = gui.get_scale(node), value=param.value, longtap_cb=param.longtap_cb }
    else
        local node = ensure_node(param)
        registered_nodes[node] = { url = msg.url(), callback = callback, click_cb=click_cb, node = node, scale = gui.get_scale(node), value=value, longtap_cb=longtap_cb }
    end
end

--- Unregister a previously registered node or all nodes
-- registered from the calling script
-- @param node_or_string
function M.unregister(node_or_string)
    if not node_or_string then
        local url = msg.url()
        for k,registered_node in pairs(registered_nodes) do
            if registered_node.url == url then
                registered_nodes[k] = nil
                longtap[k] = nil
            end
        end
    else
        local node = ensure_node(node_or_string)
        registered_nodes[node] = nil
        longtap[node] = nil
    end
end

local function shake(node, initial_scale)
    local initial_scale_ = initial_scale or registered_nodes[node].scale
    gui.cancel_animation(node, "scale.x")
    gui.cancel_animation(node, "scale.y")
    gui.set_scale(node, initial_scale_)
    local scale = gui.get_scale(node)
    gui.set_scale(node, scale * 1.2)
    gui.animate(node, "scale.x", scale.x, gui.EASING_OUTELASTIC, 0.8)
    gui.animate(node, "scale.y", scale.y, gui.EASING_OUTELASTIC, 0.8, 0.05, function()
        gui.set_scale(node, initial_scale_)
    end)
end
M.shake = shake

local function is_enabled(node)
    local enabled = gui.is_enabled(node)
    local parent = gui.get_parent(node)
    if not enabled or not parent then
        return enabled
    else
        return is_enabled(parent)
    end
end

--- Forward on_input calls to this function to detect input
-- for registered nodes
-- @param action_id,
-- @param action
-- @return true if input a registerd node received input
M.TOUCH=hash("touch")
function M.on_input(self, action_id, action)
    if action_id~= M.TOUCH then return end
    --print("action_id=",action_id,action.pressed,action.released,action.repeated)
    if action.pressed then
        local url = msg.url()
        for _,registered_node in pairs(registered_nodes) do
            if registered_node.url == url then
                local node = registered_node.node
                if is_enabled(node) and gui.pick_node(node, action.x, action.y) then
                    registered_node.pressed = true
                    if registered_node.longtap_cb then
                        registered_node.startTime=socket.gettime()
                        longtap[node]=registered_node
                    end
                    if registered_node.click_cb then registered_node.click_cb(self, registered_node.value, node) end
                    shake(node, registered_node.scale)
                    self.some_is_pressed = true
                    return true, node
                end
            end
        end
    elseif action.released then
        local url = msg.url()
        for _,registered_node in pairs(registered_nodes) do
            if registered_node.url == url then
                self.some_is_pressed = nil
                local node = registered_node.node
                local pressed = registered_node.pressed
                registered_node.pressed = false
                longtap[node] = nil
                if is_enabled(node) and gui.pick_node(node, action.x, action.y) and pressed then
                    --shake(node, registered_node.scale)
                    if registered_node.callback then registered_node.callback(self, registered_node.value, node) end
                    return true, node
                end
            end
        end
    elseif action.repeated then
        local url = msg.url()
        for _,lt_node in pairs(longtap) do
            if lt_node.url == url then
                self.some_is_pressed = nil
                local node = lt_node.node
                local pressed=lt_node.pressed
                local t=socket.gettime() - lt_node.startTime
                if t>=.8 then
                    if is_enabled(node) and gui.pick_node(node, action.x, action.y) and pressed then
                        if lt_node.longtap_cb then lt_node.longtap_cb(self, lt_node.value, node) end
                        longtap[node] = nil
                        lt_node.pressed = false
                        return true, node
                    end
                end
            end
        end
    end
    return self.some_is_pressed or false
end

return M
