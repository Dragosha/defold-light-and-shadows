local common = {}

common.is_debug = sys.get_engine_info().is_debug

common.WHITE  = vmath.vector4(1, 1, 1, 1)
common.RED    = vmath.vector4(1, 0, 0, 1)
common.GREEN  = vmath.vector4(0, 1, 0, 1)
common.YELLOW = vmath.vector4(1, 1, 0, 1)
function common.line(start_point, end_point, color)
    if common.is_debug then
        msg.post("@render:", "draw_line", { start_point = start_point, end_point = end_point, color = color } )
    end
end

function common.init_default_random()
    math.randomseed(100000 * (socket.gettime() % 1))
    math.random()
    math.random()
    math.random()
end

function common.is_web_mobile()
    if html5 then
        return html5.run("(typeof window.orientation !== 'undefined') || (navigator.userAgent.indexOf('IEMobile') !== -1);") == "true"
    end
    return false
end

function common.is_mobile()
    if common.is_mobile_checked then return common.is_mobile_checked end
    local info = sys.get_sys_info()
    if info.system_name == "Android" or info.system_name == "iPhone OS" then
        common.is_mobile_checked = true
    else
        common.is_mobile_checked = false
    end
    return common.is_mobile_checked
end


function common.clamp(x, min, max)
    return x < min and min or (x > max and max or x)
  end

common.cam_pos = vmath.vector3()
common.is_sound_on = true
common.sound_url = "/sounds#"
common.sounds = {
    [hash("button")] = "button",
 }

function common.pan(position, gain_pow)
    local v = common.cam_pos - position
    local len = vmath.length(v)
    local gain = common.clamp (20 / (len + 0.01), 0, 1) * common.clamp ((gain_pow or 1), 0, 2)
    local pan = common.clamp(-v.x / 40, -1, 1)

    return {gain = gain, pan = pan}
end

function common.play_sound(name, param, callback)
    if type(name) == "string" then
        name = hash(name)
    end

    local url = common.sounds[name]
    if common.is_sound_on and url then
        if type(url) == 'table' then url = url[math.random(#url)] end
        if url then 
            sound.play(common.sound_url..url, param, callback) 
        end
    end
end

local DISPLAY_WIDTH = sys.get_config_int("display.width")
local DISPLAY_HEIGHT = sys.get_config_int("display.height")

-- screen zoom coef if used render upscale. Need to correct screen coordinates.
-- common.zoom = 1

-- function to convert screen (mouse/touch) coordinates to
-- world coordinates given a camera component
-- this function will use the camera view and projection to
-- translate the screen coordinates into world coordinates
function common.screen_to_world(x, y, z, camera_id)
    local projection = camera.get_projection(camera_id)
    local view = camera.get_view(camera_id)
    local w, h = window.get_size()
    -- The window.get_size() function will return the scaled window size,
    -- ie taking into account display scaling (Retina screens on macOS for
    -- instance). We need to adjust for display scaling in our calculation.
    w = w / (w / DISPLAY_WIDTH)
    h = h / (h / DISPLAY_HEIGHT)

    -- https://defold.com/manuals/camera/#converting-mouse-to-world-coordinates
    local inv = vmath.inv(projection * view)
    x = (2 * x / w) - 1
    y = (2 * y / h) - 1
    z = (2 * z) - 1
    local x1 = x * inv.m00 + y * inv.m01 + z * inv.m02 + inv.m03
    local y1 = x * inv.m10 + y * inv.m11 + z * inv.m12 + inv.m13
    local z1 = x * inv.m20 + y * inv.m21 + z * inv.m22 + inv.m23
    return vmath.vector3(x1, y1, z1)
end

-- Screen to world ray. Implementation by Ross Grams 'RenderCam'
-- https://github.com/rgrams/rendercam
function common.screen_to_world_ray(x, y, camera_id)

    local projection = camera.get_projection(camera_id)
    local view = camera.get_view(camera_id)
    local w, h = window.get_size()
    local wc, hc = w / DISPLAY_WIDTH, h / DISPLAY_HEIGHT
    w = w / (wc)
    h = h / (hc)
   
    -- x = x / common.zoom / (wc)
    -- y = y / common.zoom / (hc)
    
    local m = vmath.inv(projection * view)

    -- Remap coordinates to range -1 to 1
    local x1 = (x - w * 0.5) / w * 2
    local y1 = (y - h * 0.5) / h * 2

    local np = m * vmath.vector4(x1, y1, -1, 1)
    local fp = m * vmath.vector4(x1, y1, 1, 1)
    np = np * (1/np.w)
    fp = fp * (1/fp.w)

    return vmath.vector3(np.x, np.y, np.z), vmath.vector3(fp.x, fp.y, fp.z)
end

-- Gets screen to world ray and intersects it with a plane. by Ross Grams 'RenderCam'
function common.screen_to_world_plane(x, y, camera_id, planeNormal, pointOnPlane)
    local np, fp = common.screen_to_world_ray(x, y, camera_id)
    local denom = vmath.dot(planeNormal, fp - np)
    if denom == 0 then
        -- ray is perpendicular to plane normal, so there are either 0 or infinite intersections
        return
    end
    local numer = vmath.dot(planeNormal, pointOnPlane - np)
    return vmath.lerp(numer / denom, np, fp)
end

-- World to screeen. by Ross Grams 'RenderCam'
function common.world_to_screen(pos, camera_id)
    local projection = camera.get_projection(camera_id)
    local view = camera.get_view(camera_id)
    local w, h = window.get_size()
    -- w = w * common.zoom
    -- h = h * common.zoom
    -- w = w / (w / DISPLAY_WIDTH)
    -- h = h / (h / DISPLAY_HEIGHT)

    local m = projection * view
    local pv = vmath.vector4(0, 0, 0, 1)
    pv.x, pv.y, pv.z, pv.w = pos.x, pos.y, pos.z, 1

    pv = m * pv
    pv = pv * (1/pv.w)
    pv.x = (pv.x / 2 + 0.5) * w
    pv.y = (pv.y / 2 + 0.5) * h

    return pv.x, pv.y, 0
end


--- math3d by aglitchman https://github.com/indiesoftby/defold-scene3d/blob/main/scene3d/helpers/math3d.lua
--- Gradually changes a value towards a desired goal over time.
-- Based on Game Programming Gems 4, pp. 98-101.
-- @param a Current value.
-- @param b Target value.
-- @param cur_velocity The current velocity.
-- @param smooth_time Approximately the time it will take to reach the target. A smaller value will result in a faster arrival at the target.
-- @param max_speed Optionally clamp the maximum speed.
-- @param dt Delta time.
-- @return An interpolated value.
-- @usage
-- local obj_position = go.get("/object_to_follow", "position")
-- local camera_pos = go.get("/camera_object", "position")
-- local cur_velocity = self.camera_velocity -- The type is `vmath.vector3(0)`. Store this variable somewhere, for example in `self`.
-- local smooth_time = 0.3
-- local max_speed = nil
-- -- dt is defined in `update()`
-- camera_pos.x, cur_velocity.x = math3d.smooth_damp(camera_pos.x, obj_position.x, cur_velocity.x, smooth_time, max_speed, dt)
-- camera_pos.y, cur_velocity.x = math3d.smooth_damp(camera_pos.x, obj_position.x, cur_velocity.x, smooth_time, max_speed, dt)
-- camera_pos.z, cur_velocity.z = math3d.smooth_damp(camera_pos.z, obj_position.z, cur_velocity.z, smooth_time, max_speed, dt)
-- go.set("/camera_object", "position", camera_pos)
function common.smooth_damp(a, b, cur_velocity, smooth_time, max_speed, dt)
    smooth_time = math.max(0.0001, smooth_time)
    local omega = 2 / smooth_time

    local x = omega * dt
    local exp = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x)
    local change = a - b
    local initial_b = b

    if max_speed then
        local max_change = max_speed * smooth_time
        change = common.clamp(change, -max_change, max_change)
    end
    b = a - change

    local temp = (cur_velocity + omega * change) * dt
    cur_velocity = (cur_velocity - omega * temp) * exp
    local result = b + (change + temp) * exp

    if (initial_b - a > 0) == (result > initial_b) then
        result = initial_b
        cur_velocity = (result - initial_b) / dt
    end

    return result, cur_velocity
end

return common