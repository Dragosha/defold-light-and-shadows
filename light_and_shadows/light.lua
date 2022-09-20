-----------------------------------------------------------------
-- Copyright (c) 2022 Igor Suntsev
-- http://dragosha.com
-- MIT License
-----------------------------------------------------------------

local constants = require "light_and_shadows.constants"
local light = {}

light.list = {}
light.cam_pos = vmath.vector3()
light.cam_view = vmath.quat()

local fog_default = vmath.vector4(0.1, 0.2, 0.5, 0.43)
local fog = vmath.vector4(10, 100, 1, 0.4)
local ambient_default = vmath.vector4(0.3, 0.2, 0.1, 3)

function light.set_color(fog_color, fog, ambient, clear_color)
    if ambient then constants.ambient = ambient end
    if fog_color then constants.fog_color = fog_color end
    if fog then constants.fog = fog end
    if clear_color then constants.clear_color = clear_color end
    msg.post("@render:", "clear_color", {color = clear_color or fog_color})
end

function light.reset(self)
    constants.lights    = {}
    constants.ambient   = ambient_default
    constants.fog_color = fog_default
    constants.fog       = fog
end

-- Prepare constants for the renderscript.
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
        end

        local dx = light.cam_pos.x - obj.position.x
        local dy = light.cam_pos.z - obj.position.z
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
        table.insert(lights, n, {position = obj.position, color = obj.current_value, distance = distance, power = obj.value.w})

        -- rotate the light source (particle fx) to look to front of camera view if needed
        if obj.rotate then go.set_rotation(light.cam_view, id) end
    end

    --
    -- Reduce power of light sources depends of distance from camera's look at point.
    -- You may remove this loop.
    for i = ind, #lights do
        local a = lights[i]
        local dist  = a.distance / 1500
        dist = dist < 1 and 1 or dist
        a.color.w = a.power * dist --* dist * dist * dist
        -- print( i, a.color.w, dist )
    end

    --
    constants.cam_look_at_position.x = light.cam_pos.x
    constants.cam_look_at_position.y = light.cam_pos.y
    constants.cam_look_at_position.z = light.cam_pos.z

end


return light