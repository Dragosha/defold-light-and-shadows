
local M = {}

-- Check if 'shared_state' setting is on
if sys.get_config("script.shared_state") ~= "1" then
    error("ERROR - rendercam - 'shared_state' setting in game.project must be enabled for rendercam to work.", 0)
end

local SCALEMODE_EXPANDVIEW = hash("expandView")
local SCALEMODE_FIXEDAREA = hash("fixedArea")
local SCALEMODE_FIXEDWIDTH = hash("fixedWidth")
local SCALEMODE_FIXEDHEIGHT = hash("fixedHeight")

M.ortho_zoom_mult = 0.01
M.follow_lerp_speed = 3

-- Data table for the fallback camera - used when no user camera is active
local fallback_cam = {
    should_print_warning = true, -- Used to print a warning on the first render update that the fallback cam is used
    orthographic = true, scaleMode = SCALEMODE_EXPANDVIEW, orthoScale = 1, useViewArea = false,
    viewArea = vmath.vector3(960, 640, 0), halfViewArea = vmath.vector3(480, 320, 0),
    fixedAspectRatio = false, aspectRatio = 1.5, worldZ = 0, nearZ = -1, farZ = 1, abs_nearZ = -1,
    abs_farZ = 1, lpos = vmath.vector3(), wpos = vmath.vector3(), wupVec = vmath.vector3(0, 1, 0),
    wforwardVec = vmath.vector3(0, 0, -1), lupVec = vmath.vector3(0, 1, 0),
    lforwardVec = vmath.vector3(0, 0, -1), lrightVec = vmath.vector3(1, 0, 0),
    following = false, follows = {}, recoils = {}, shakes = {},
}

M.view = vmath.matrix4() -- current view matrix
M.proj = vmath.matrix4() -- current proj matrix

-- Current window size
M.window = vmath.vector3() -- only set in `M.update_window_size`, in `M.update_window`
-- Viewport offset, size, and scale - only differs from M.window when using a fixed aspect ratio camera
M.viewport = { x = 0, y = 0, width = M.window.x, height = M.window.y, scale = { x = 1, y = 1 } }
-- Initial window size - set on init in render script
M.configWin = vmath.vector3()

-- GUI "transform" data - set in `calculate_gui_adjust_data` and used for screen-to-gui transforms in multiple places
--				Fit		(scale)		(offset)	Zoom						Stretch
M.guiAdjust = { [0] = {sx=1, sy=1, ox=0, oy=0}, [1] = {sx=1, sy=1, ox=0, oy=0}, [2] = {sx=1, sy=1, ox=0, oy=0} }
M.guiOffset = vmath.vector3()

-- GUI Adjust modes - these match up with the gui library properties (gui.ADJUST_FIT, etc.)
M.GUI_ADJUST_FIT = 0
M.GUI_ADJUST_ZOOM = 1
M.GUI_ADJUST_STRETCH = 2

local cameras = {} -- master table of camera data tables. Elements added and removed on M.camera_init and M.camera_final
local curCam = fallback_cam -- current camera data table, defaults and resets to `fallback_cam` if no user camera is active

-- Vectors used in calculations for public transform functions
local nv = vmath.vector4(0, 0, -1, 1)
local fv = vmath.vector4(0, 0, 1, 1)
local pv = vmath.vector4(0, 0, 0, 1)

-- ---------------------------------------------------------------------------------
--| 							PRIVATE FUNCTIONS									|
-- ---------------------------------------------------------------------------------

local function get_target_worldViewSize(cam, lastX, lastY, lastWinX, lastWinY, winX, winY)
    local x, y

    if cam.fixedAspectRatio then
        if cam.scaleMode == SCALEMODE_EXPANDVIEW then
            local z = math.max(lastX / lastWinX, lastY / lastWinY)
            x, y = winX * z, winY * z
        else -- Fixed Area, Fixed Width, and Fixed Height all work the same with a fixed aspect ratio
            --		The proportion and world view area remain the same.
            x, y = lastX, lastY
        end
        -- Enforce aspect ratio
        local scale = math.min(x / cam.aspectRatio, y / 1)
        x, y = scale * cam.aspectRatio, scale

    else -- Non-fixed aspect ratio
        if cam.scaleMode == SCALEMODE_EXPANDVIEW then
            local z = math.max(lastX / lastWinX, lastY / lastWinY)
            x, y = winX * z, winY * z
        elseif cam.scaleMode == SCALEMODE_FIXEDAREA then
            if not cam.fixedAspectRatio then -- x, y stay at lastX, lastY with fixed aspect ratio
                local lastArea = lastX * lastY
                local windowArea = winX * winY
                local axisScale = math.sqrt(lastArea / windowArea)
                x, y = winX * axisScale, winY * axisScale
            end
        elseif cam.scaleMode == SCALEMODE_FIXEDWIDTH then
            local ratio = winX / winY
            x, y = lastX, lastX / ratio
        elseif cam.scaleMode == SCALEMODE_FIXEDHEIGHT then
            local ratio = winX / winY
            x, y = lastY * ratio, lastY
        else
            error("rendercam - get_target_worldViewSize() - camera: " .. cam.id .. ", scale mode not found.")
        end
    end

    return x, y
end

local function get_fov(distance, y) -- must use Y, not X
    return math.atan(y / distance) * 2
end

local function calculate_gui_adjust_data(winX, winY, configX, configY)
    local sx, sy = winX / configX, winY / configY

    -- Fit
    local adj = M.guiAdjust[M.GUI_ADJUST_FIT]
    local scale = math.min(sx, sy)
    adj.sx = scale;  adj.sy = scale
    adj.ox = (winX - configX * adj.sx) * 0.5 / adj.sx
    adj.oy = (winY - configY * adj.sy) * 0.5 / adj.sy

    -- Zoom
    adj = M.guiAdjust[M.GUI_ADJUST_ZOOM]
    scale = math.max(sx, sy)
    adj.sx = scale;  adj.sy = scale
    adj.ox = (winX - configX * adj.sx) * 0.5 / adj.sx
    adj.oy = (winY - configY * adj.sy) * 0.5 / adj.sy

    -- Stretch
    adj = M.guiAdjust[M.GUI_ADJUST_STRETCH]
    adj.sx = sx;  adj.sy = sy
    -- distorts to fit window, offsets always zero
end


-- ---------------------------------------------------------------------------------
--| 					PUBLIC FUNCTIONS I: CAMERA STUFF							|
-- ---------------------------------------------------------------------------------

function M.activate_camera(cam_id)
    if cameras[cam_id] then
        if cameras[cam_id] ~= curCam then
            if curCam then curCam.active = false end
            curCam = cameras[cam_id]
            msg.post("@render:", "update window")
        end
    else
        print("WARNING: rendercam.activate_camera() - camera ".. cam_id .. " not found. ")
    end
end

function M.camera_init(cam_id, data)
    if cameras[cam_id] then
        print("ERROR: rendercam.camera_init() - Camera name conflict with ID: " .. cam_id .. ". \n\tNew camera will overwrite the old! Your cameras must have unique IDs.")
    end
    cameras[cam_id] = data
    if data.active then
        M.activate_camera(cam_id)
    end
end

function M.camera_final(cam_id)
    if curCam == cameras[cam_id] then
        curCam = fallback_cam
        msg.post("@render:", "update window")
    end
    cameras[cam_id] = nil
end

function M.zoom(z, cam_id)
    local cam = cam_id and cameras[cam_id] or curCam
    if cam.orthographic then
        cam.orthoScale = cam.orthoScale + z * M.ortho_zoom_mult
    else
        cam.lpos = cam.lpos - cam.lforwardVec * z
        go.set_position(cam.lpos, cam.id) -- don't need to check for fallback_cam because it's orthographic
    end
end

function M.get_ortho_scale(cam_id)
    local cam = cam_id and cameras[cam_id] or curCam
    if cam.orthographic then
        return cam.orthoScale
    else
        print("ERROR: rendercam.get_ortho_scale() - this camera is not orthographic")
    end
end

function M.set_ortho_scale(s, cam_id)
    local cam = cam_id and cameras[cam_id] or curCam
    if cam.orthographic then
        cam.orthoScale = s
    else
        print("ERROR: rendercam.set_ortho_scale() - this camera is not orthographic")
    end
end

function M.pan(dx, dy, cam_id)
    local cam = cam_id and cameras[cam_id] or curCam
    cam.lpos = cam.lpos + cam.lrightVec * dx + cam.lupVec * dy
    if cam.id then go.set_position(cam.lpos, cam.id) end -- fallback_cam has no cam.id, it will ignore panning
end

function M.shake(dist, dur, cam_id)
    local cam = cam_id and cameras[cam_id] or curCam
    table.insert(cam.shakes, { dist = dist, dur = dur, t = dur })
end

function M.recoil(vec, dur, cam_id)
    local cam = cam_id and cameras[cam_id] or curCam
    table.insert(cam.recoils, { vec = vec, dur = dur, t = dur })
end

function M.stop_shaking(cam_id)
    local cam = cam_id and cameras[cam_id] or curCam
    cam.shakes = {}
    cam.recoils = {}
end

function M.follow(target_id, allowMultiFollow, cam_id)
    local cam = cam_id and cameras[cam_id] or curCam
    if allowMultiFollow then
        table.insert(cam.follows, target_id)
    else
        cam.follows = { target_id }
    end
    cam.following = true
end

function M.unfollow(target_id, cam_id)
    local cam = cam_id and cameras[cam_id] or curCam
    for i, v in ipairs(cam.follows) do
        if v == target_id then
            table.remove(cam.follows, i)
            if #cam.follows == 0 then cam.following = false end
        end
    end
end

function M.follow_lerp_func(curPos, targetPos, dt)
    return vmath.lerp(dt * M.follow_lerp_speed, curPos, targetPos)
end

-- ---------------------------------------------------------------------------------
--| 			   PUBLIC FUNCTIONS II: WINDOW UPDATE LISTENERS						|
-- ---------------------------------------------------------------------------------

local listeners = {}

function M.add_window_listener(url)
    table.insert(listeners, url)
end

function M.remove_window_listener(url)
    for i, v in ipairs(listeners) do
        if v == url then
            table.remove(listeners, i)
        end
    end
end

-- ---------------------------------------------------------------------------------
--| 					PUBLIC FUNCTIONS III: RENDER SCRIPT							|
-- ---------------------------------------------------------------------------------

function M.calculate_view() -- called from render script on update
    -- The view matrix is just the camera object transform. (Translation & rotation. Scale is ignored)
    --		It changes as the camera is translated and rotated, but has nothing to do with aspect ratio or anything else.

    if curCam.should_print_warning then -- using fallback camera and haven't printed the warning yet
        print("NOTE: rendercam - No active camera found this frame...using fallback camera. There will be no more warnings about this.")
        fallback_cam.should_print_warning = false
    end

    M.view = vmath.matrix4_look_at(curCam.wpos, curCam.wpos + curCam.wforwardVec, curCam.wupVec)
    return M.view
end

function M.calculate_proj() -- called from render script on update
    if curCam.orthographic then
        local x = curCam.halfViewArea.x * curCam.orthoScale
        local y = curCam.halfViewArea.y * curCam.orthoScale
        M.proj = vmath.matrix4_orthographic(-x, x, -y, y, curCam.nearZ, curCam.farZ)
    else -- perspective
        M.proj = vmath.matrix4_perspective(curCam.fov, curCam.aspectRatio, curCam.nearZ, curCam.farZ)
    end
    return M.proj
end

function M.cur_cam_position()
    return curCam.wpos
end

function M.get_cur_cam()
    return curCam.halfViewArea.x, curCam.halfViewArea.y
end

function M.update_window_size(x, y)
    if x > 0 and y > 0 then
        M.window.x = x;  M.window.y = y
        M.viewport.width = x;  M.viewport.height = y -- if using a fixed aspect ratio this will be immediately overwritten in M.update_window
    end
end

function M.update_window(newX, newY)
    if curCam then
        newX = newX or M.window.x
        newY = newY or M.window.y
        
        if newX == 0 or newY == 0 then
            return
        end

        local x, y = get_target_worldViewSize(curCam, curCam.viewArea.x, curCam.viewArea.y, M.window.x, M.window.y, newX, newY)
        curCam.viewArea.x = x;  curCam.viewArea.y = y
        curCam.aspectRatio = x / y
        M.update_window_size(newX, newY)

        if curCam.fixedAspectRatio then -- if fixed aspect ratio, calculate viewport cropping
            local scale = math.min(M.window.x / curCam.aspectRatio, M.window.y / 1)
            M.viewport.width = curCam.aspectRatio * scale
            M.viewport.height = scale

            -- Viewport offset: bar on edge of screen from fixed aspect ratio
            M.viewport.x = (M.window.x - M.viewport.width) * 0.5
            M.viewport.y = (M.window.y - M.viewport.height) * 0.5

            -- For screen-to-viewport coordinate conversion
            M.viewport.scale.x = M.viewport.width / newX
            M.viewport.scale.y = M.viewport.height / newY
        else
            M.viewport.x = 0;  M.viewport.y = 0
            M.viewport.width = newX;  M.viewport.height = newY
        end

        if curCam.orthographic then
            curCam.halfViewArea.x = x/2;  curCam.halfViewArea.y = y/2
        else
            curCam.fov = get_fov(curCam.viewArea.z, curCam.viewArea.y * 0.5)
        end

        calculate_gui_adjust_data(M.window.x, M.window.y, M.configWin.x, M.configWin.y)

        -- send window update messages to listeners
        for i, v in ipairs(listeners) do
            msg.post(v, "window_update", { window = M.window, viewport = M.viewport, aspect = curCam.aspectRatio, fov = curCam.fov })
        end
    end
end

-- ---------------------------------------------------------------------------------
--| 					  PUBLIC FUNCTIONS IV: TRANSFORMS							|
-- ---------------------------------------------------------------------------------

function M.screen_to_viewport(x, y, delta)
    if delta then
        x = x / M.viewport.scale.x
        y = y / M.viewport.scale.y
    else
        x = (x - M.viewport.x) / M.viewport.scale.x
        y = (y - M.viewport.y) / M.viewport.scale.y
    end
    return x, y
end

function M.screen_to_world_2d(x, y, delta, worldz, raw)
    worldz = worldz or curCam.worldZ

    if curCam.fixedAspectRatio then
        x, y = M.screen_to_viewport(x, y, delta)
    end

    local m = not delta and vmath.inv(M.proj * M.view) or vmath.inv(M.proj)

    -- Remap coordinates to range -1 to 1
    x1 = (x - M.window.x * 0.5) / M.window.x * 2
    y1 = (y - M.window.y * 0.5) / M.window.y * 2

    if delta then x1 = x1 + 1;  y1 = y1 + 1 end

    nv.x, nv.y = x1, y1
    fv.x, fv.y = x1, y1
    local np = m * nv
    local fp = m * fv
    np = np * (1/np.w)
    fp = fp * (1/fp.w)

    local t = ( worldz - curCam.abs_nearZ) / (curCam.abs_farZ - curCam.abs_nearZ) -- normalize desired Z to 0-1 from abs_nearZ to abs_farZ
    local worldpos = vmath.lerp(t, np, fp)

    if raw then return worldpos.x, worldpos.y, worldpos.z
    else return vmath.vector3(worldpos.x, worldpos.y, worldpos.z) end -- convert vector4 to vector3
end

-- Returns start and end points for a ray from the camera through the supplied screen coordinates
-- Start point is on the camera near plane, end point is on the far plane.
function M.screen_to_world_ray(x, y, raw)
    if curCam.fixedAspectRatio then -- convert screen coordinates to viewport coordinates
        x, y = M.screen_to_viewport(x, y)
    end

    local m = vmath.inv(M.proj * M.view)

    -- Remap coordinates to range -1 to 1
    local x1 = (x - M.window.x * 0.5) / M.window.x * 2
    local y1 = (y - M.window.y * 0.5) / M.window.y * 2

    nv.x, nv.y = x1, y1
    fv.x, fv.y = x1, y1
    local np = m * nv
    local fp = m * fv
    np = np * (1/np.w)
    fp = fp * (1/fp.w)

    if raw then return np.x, np.y, np.z, fp.x, fp.y, fp.z
    else return vmath.vector3(np.x, np.y, np.z), vmath.vector3(fp.x, fp.y, fp.z) end
end

-- Gets screen to world ray and intersects it with a plane
function M.screen_to_world_plane(x, y, planeNormal, pointOnPlane)
    local np, fp = M.screen_to_world_ray(x, y)
    local denom = vmath.dot(planeNormal, fp - np)
    if denom == 0 then
        -- ray is perpendicular to plane normal, so there are either 0 or infinite intersections
        return
    end
    local numer = vmath.dot(planeNormal, pointOnPlane - np)
    return vmath.lerp(numer / denom, np, fp)
end

function M.screen_to_gui(x, y, adjust, isSize)
    if not isSize then
        x = x / M.guiAdjust[adjust].sx - M.guiAdjust[adjust].ox
        y = y / M.guiAdjust[adjust].sy - M.guiAdjust[adjust].oy
    else
        x = x / M.guiAdjust[adjust].sx
        y = y / M.guiAdjust[adjust].sy
    end
    return x, y
end

function M.screen_to_gui_pick(x, y)
    return x / M.guiAdjust[2].sx, y / M.guiAdjust[2].sy
end

function M.world_to_screen(pos, adjust, raw)
    local m = M.proj * M.view
    pv.x, pv.y, pv.z, pv.w = pos.x, pos.y, pos.z, 1

    pv = m * pv
    pv = pv * (1/pv.w)
    pv.x = (pv.x / 2 + 0.5) * M.viewport.width + M.viewport.x
    pv.y = (pv.y / 2 + 0.5) * M.viewport.height + M.viewport.y

    if adjust then
        pv.x = pv.x / M.guiAdjust[adjust].sx - M.guiAdjust[adjust].ox
        pv.y = pv.y / M.guiAdjust[adjust].sy - M.guiAdjust[adjust].oy
    end

    if raw then return pv.x, pv.y, 0
    else return vmath.vector3(pv.x, pv.y, 0) end
end

return M
