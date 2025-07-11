-----------------------------------------------------------------
-- Copyright (c) 2022 Igor Suntsev
-- http://dragosha.com
-- MIT License
-----------------------------------------------------------------

local constants = require "light_and_shadows.constants"
local light = {}

light.list = {}
light.cam_look_at = vmath.vector3()
light.cam_position = vmath.vector3()
light.cam_view = vmath.quat()
local top_v     = vmath.vector3(0, 1, 0)
light.top_v = top_v

light.attenuation_coefficient = 1500

local fog_default = vmath.vector4(0.1, 0.2, 0.5, 0.43)
local fog = vmath.vector4(10, 100, 1, 0.4)
local ambient_default = vmath.vector4(0.3, 0.2, 0.1, 3)

---Setup base light uniform constants
---@param fog_color vector4 RGB color
---@param fog vector4 Min max Z coordinate in the view space where the fog should begining and ending
---@param ambient vector4 Color
---@param clear_color vector4 Color to clear default render target or background color.
function light.set_color(fog_color, fog, ambient, clear_color)
    if ambient then constants.ambient = ambient end
    if fog_color then constants.fog_color = fog_color end
    if fog then constants.fog = fog end
    if clear_color then constants.clear_color = clear_color end
    msg.post("@render:", "clear_color", {color = clear_color or fog_color})
end

---Setup the camera and the camera look at point positions 
---@param cam_rotation quaternion
---@param cam_look_at_position vector3
---@param cam_position vector3
function light.set_position(cam_rotation, cam_look_at_position, cam_position)
    light.cam_view = cam_rotation
    light.cam_look_at = cam_look_at_position
    light.cam_position = cam_position
end

function light.reset(self)
    constants.lights    = {}
    constants.ambient   = ambient_default
    constants.fog_color = fog_default
    constants.fog       = fog
end

---Prepare constants for the render script.
function light.update(self, dt)

    local ind = 1

    constants.lights = {}
    local lights = constants.lights

    -- Sort all light sources by distance from a camera looks at point (usually, center of the screen).
    for id, obj in pairs(light.list) do

        obj.current_value = obj.current_value or vmath.vector4()

        if not obj.static then
            local wp = go.get_world_position(id)
            obj.position.x = wp.x
            obj.position.y = wp.y + (obj.y_offset or 0)
            obj.position.z = wp.z
            if obj.direction.w > 0 and not obj.static_spot then
                local temp = vmath.rotate(go.get_world_rotation(id), light.top_v)
                obj.direction.x = temp.x
                obj.direction.y = temp.y
                obj.direction.z = temp.z
            end
        end

        local dx = light.cam_look_at.x - obj.position.x
        local dy = light.cam_look_at.z - obj.position.z
        local distance = dx * dx + dy * dy

        local n = #lights + 1
        if obj.num > 0 then
            ind = ind + 1
            n = 1
        else
            for i = ind, #lights do
                if distance < lights[i].distance then 
                    n = i
                    break
                end
            end
        end
        table.insert(lights, n, {position = obj.position, color = obj.current_value, direction = obj.direction, distance = distance, power = obj.value.w})

        -- rotate the light source (particle fx) to look to front of camera view if needed
        if obj.rotate then go.set_rotation(light.cam_view, id) end
    end

    --
    -- Reduce power of light sources depends of distance from camera's look at point.
    -- You may remove this loop.
    for i = ind, #lights do
        local a = lights[i]
        local dist  = a.distance / light.attenuation_coefficient
        dist = dist < 1 and 1 or dist
        a.color.w = a.power * dist --* dist * dist * dist
        -- print( i, a.color.w, dist )
    end

    --
    constants.cam_look_at_position.x = light.cam_look_at.x
    constants.cam_look_at_position.y = light.cam_look_at.y
    constants.cam_look_at_position.z = light.cam_look_at.z

    constants.cam_position.x = light.cam_position.x
    constants.cam_position.y = light.cam_position.y
    constants.cam_position.z = light.cam_position.z

end


return light