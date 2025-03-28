local M = {}
M.ANALOG = hash("ANALOG")
M.BUTTON = hash("BUTTON")

local function get_node(node_or_node_id)
    local node = (type(node_or_node_id) == "string" and gui.get_node(node_or_node_id) or node_or_node_id)
    return node
end

function M.register_button(self, node_or_node_id, message_id)
    self.register_buttons_list = self.register_buttons_list or {}
    local node = get_node(node_or_node_id)
    self.register_buttons_list[node_or_node_id] = {
        message_id = message_id,
        node = node,
        scale = gui.get_scale(node),
        color = gui.get_color(node)
    }
end

function M.shake(node, initial_scale)
    gui.cancel_animation(node, "scale.x")
    gui.cancel_animation(node, "scale.y")
    gui.set_scale(node, initial_scale)
    local scale = gui.get_scale(node)
    gui.set_scale(node, scale * 1.2)
    gui.animate(node, "scale.x", scale.x, gui.EASING_OUTELASTIC, 0.8)
    gui.animate(node, "scale.y", scale.y, gui.EASING_OUTELASTIC, 0.8, 0.05, function()
        gui.set_scale(node, initial_scale)
    end)
end

function M.init(self)
    self.register_buttons_list = {}
    self.gamepads_list = {}
end

--@param id of stick 
--@param stick_zone node
--@param stick node
--@param pad node
--@param initial_alpha value 0 - 1
--@param touch_alpha value 0 - 1
function M.register_stick(self, id, stick_zone, stick, pad, initial_alpha, touch_alpha)
    self.gamepads_list = self.gamepads_list or {}
    assert(id, "You mast provide an id for register the stick")
    local data = {
        id = id,
        stick_zone = get_node(stick_zone),
        stick_node = get_node(stick),
        pad_node = get_node(pad),
        initial_alpha = initial_alpha,
        touch_alpha = touch_alpha,
    }
    self.gamepads_list[id] = data
    gui.set_alpha(data.pad_node, data.initial_alpha)
end

local function post_to_listener(self, message_id, message)
    if self.listener then
        msg.post(self.listener, message_id, message or {})
    end
end

local function get_screen_aspect_koef()
    local window_x, window_y = window.get_size()
    local stretch_x = window_x / gui.get_width()
    local stretch_y = window_y / gui.get_height()
    local min = math.min(stretch_x, stretch_y)
    stretch_x = stretch_x / min
    stretch_y = stretch_y / min
    local zoom = math.max(math.max(stretch_x, stretch_y) / 2, 1)
    return  stretch_x / zoom,
    stretch_y / zoom,
    zoom

end

M.get_aspect_ratio = get_screen_aspect_koef


local v0 = vmath.vector3(0, 0, 0)
local function handle_touch(self, touch, touch_index)
    if touch.pressed then
        for __, v in pairs( self.register_buttons_list ) do
            if gui.pick_node(v.node, touch.x, touch.y) then
                post_to_listener(self, M.BUTTON, {id = v.message_id, pressed = true })
                v.pressed = true
                self.some_is_pressed = true
                M.shake(v.node, v.scale)
                return true
            end
        end
        -- stick touch detecting: 
        for _, v in pairs(self.gamepads_list) do
            if gui.pick_node(v.stick_zone, touch.x, touch.y) then
                -- pprint(touch, get_screen_aspect_koef())
                gui.animate(v.pad_node, "color.w", v.touch_alpha, gui.EASING_OUTCUBIC, .5)
                gui.cancel_animation(v.stick_node, gui.PROP_POSITION)
                gui.set_position(v.stick_node, v0)
                local sx, sy, zoom = get_screen_aspect_koef()
                local touch_position = vmath.vector3(touch.x * sx, touch.y * sy, 0)
                gui.set_scale(v.pad_node, vmath.vector3(zoom, zoom, 0))
                gui.set_screen_position(v.pad_node, vmath.vector3(touch.screen_x, touch.screen_y, 0))
                -- gui.set_position(v.pad_node, touch_position)
                v.analog_pressed = {
                    pos = touch_position,
                    index = touch_index 
                }
                post_to_listener(self, M.ANALOG, { id = v.id, x = 0, y = 0, pressed = true })
                return true
            end
        end
    elseif touch.released then
        -- release stick
        for _, v in pairs(self.gamepads_list) do
            if v.analog_pressed and v.analog_pressed.index == touch_index then
                gui.animate(v.pad_node, "color.w", v.initial_alpha, gui.EASING_OUTCUBIC, .5)
                gui.animate(v.stick_node, gui.PROP_POSITION, v0, gui.EASING_OUTQUAD, 0.2)
                post_to_listener(self, M.ANALOG, { id = v.id, x = 0, y = 0, released = true })
                v.analog_pressed = nil
                return true
            end
        end

        self.some_is_pressed = nil
        for __, v in pairs( self.register_buttons_list ) do
            if gui.pick_node(v.node, touch.x, touch.y) and v.pressed then
                post_to_listener(self, M.BUTTON, {id = v.message_id, released = true })
                v.pressed = nil
                return true
            end
        end
        -- Release all pressed self.register_buttons_list for prevent stuck of button when tap on the button and untap outside it
        for __, v in pairs( self.register_buttons_list ) do
            if v.pressed then
                post_to_listener(self, M.BUTTON, {id = v.message_id, released = true })
                v.pressed = nil
            end
        end

    else
        for _, v in pairs(self.gamepads_list) do
            if v.analog_pressed and v.analog_pressed.index == touch_index then
                local sx, sy = get_screen_aspect_koef()
                local touch_position = vmath.vector3(touch.x * sx, touch.y * sy, 0)
                local diff = v.analog_pressed.pos - touch_position
                local dir = vmath.normalize(diff)
                local distance = vmath.length(diff)
                if distance > 0 then
                    local radius = 100
                    if distance > radius then
                        touch_position = - dir * radius
                        distance = radius
                    else
                        touch_position = touch_position - v.analog_pressed.pos
                    end
                    gui.set_position(v.stick_node, touch_position)
                    post_to_listener(self, M.ANALOG, { id = v.id, x = -dir.x * distance / radius, y = -dir.y * distance / radius })
                end
                return true
            end
        end
    end

    return self.some_is_pressed or false
end

local touch = hash("touch")
function M.on_input(self, action_id, action, touch_h)
    if action.touch then
        local ret = false
        for i,tp in pairs(action.touch) do
            if handle_touch(self, tp, i) then
                ret = true
            end
        end
        return ret
    elseif action_id == (touch_h or touch) then
        return handle_touch(self, action, 0)
    end
end

return M
