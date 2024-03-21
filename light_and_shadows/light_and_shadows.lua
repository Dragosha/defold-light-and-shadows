local light_and_shadows = {}

local constants = require "light_and_shadows.constants"
local rendercam = require "rendercam.rendercam"

local top = vmath.vector3(0, 1, 0)
local v0 = vmath.vector4(0, 0, 0, 0) -- zero vector4

-- 1 - max quality
-- 2 - low
-- 3 - extra low / no shadow cast
light_and_shadows.shadow_quality = 1

local BUFFER_RESOLUTION = 2048 -- Size of shadow map. Select value from: 1024/2048/4096. More is better quality.

-- Projection resolution of shadow map to the game world. Smaller size is better shadow quality,
-- but shadows will cast only around the screen center (or a point that camera looks at).
-- This value also depends on camera zoom. Feel free to adjust it.
local PROJECTION_RESOLUTION = 400 

function light_and_shadows.create_depth_buffer(w,h)
    local color_params = {
        format     = render.FORMAT_RGBA,
        -- format     = render.FORMAT_R32F,
        width      = w,
        height     = h,
        min_filter = render.FILTER_NEAREST,
        mag_filter = render.FILTER_NEAREST,
        u_wrap     = render.WRAP_CLAMP_TO_EDGE,
        v_wrap     = render.WRAP_CLAMP_TO_EDGE }

        local depth_params = { 
            format        = render.FORMAT_DEPTH,
            width         = w,
            height        = h,
            min_filter    = render.FILTER_NEAREST,
            mag_filter    = render.FILTER_NEAREST,
            u_wrap        = render.WRAP_CLAMP_TO_EDGE,
            v_wrap        = render.WRAP_CLAMP_TO_EDGE }

    return render.render_target("shadow_buffer", {[render.BUFFER_COLOR_BIT] = color_params, [render.BUFFER_DEPTH_BIT] = depth_params })
end


function light_and_shadows.init(self)
    -- self.shadowmap_buffer = light_and_shadows.create_depth_buffer(BUFFER_RESOLUTION, BUFFER_RESOLUTION)
    self.shadowmap_buffer = "shadowmap"

    -- Use this for directional lights
    local proj_w = PROJECTION_RESOLUTION
    local proj_h = PROJECTION_RESOLUTION
    self.light_projection = vmath.matrix4_orthographic(-proj_w/2, proj_w/2, -proj_h/2, proj_h/2, -500, 500)
    -- self.light_projection = vmath.matrix4_perspective(3.141592/2, 1, 1, 1000)

    self.constants.lights = {}
    self.constants.colors = {}

    self.bias_matrix    = vmath.matrix4()
    self.bias_matrix.c0 = vmath.vector4(0.5, 0.0, 0.0, 0.0)
    self.bias_matrix.c1 = vmath.vector4(0.0, 0.5, 0.0, 0.0)
    self.bias_matrix.c2 = vmath.vector4(0.0, 0.0, 0.5, 0.0)
    self.bias_matrix.c3 = vmath.vector4(0.5, 0.5, 0.5, 1.0)
end

local sun = vmath.vector3()
local temp = vmath.vector4()

function light_and_shadows.update_light(self)
    -- Direct light
    sun.x = constants.sun_position.x
    sun.y = constants.sun_position.y
    sun.z = constants.sun_position.z
   
    -- Sun position, color and shadow intensity
    self.constants.light = constants.sun_position or v0
    self.constants.color0 = constants.sun_color or v0
    self.constants.shadow_color = constants.shadow_color or v0

    -- Point lights uniform constants.
    -- Fills light position and color arrays.
    -- 16 simultaneously calculation light sources.
    -- If you need to change this amount of light sources you should to change it in fragment shader as well.
    -- In fragment shaders (.fp) change arrays size here:
    -- #define LIGHT_COUNT 16
    --                     ^^ 
    -- ...
    for i = 1, 16 do
        local l = constants.lights[i]
        if l then
            self.constants.lights[i] = constants.lights[i].position or v0
            self.constants.colors[i] = constants.lights[i].color or v0
        else
            self.constants.lights[i] = v0
            self.constants.colors[i] = v0
        end
    end

    -- Setup an ambient and a fog constants
    if constants.ambient then self.constants.ambient = constants.ambient end
    if constants.fog_color then self.constants.fog_color = constants.fog_color end
    if constants.fog then self.constants.fog = constants.fog end
    if constants.tint then self.constants.tint = constants.tint end

    if light_and_shadows.shadow_quality <  3 then
        local pos_light = constants.cam_look_at_position + sun
        self.light_transform = vmath.matrix4_look_at(pos_light, constants.cam_look_at_position, top)
        local mtx_light = self.bias_matrix * self.light_projection * self.light_transform
        self.constants.mtx_light = mtx_light
    end
    
    if self.bias then self.constants.b = self.bias end

    -- Setup camera world position uniform constant (vector4)
    -- It's used in shader to calculate speculars by phong model.
    -- If you are switching to "low spec" fragment shaders you may remove code below.
    -- Standart rendercam extension doesn't contain this method.
    local p = rendercam.cur_cam_position()
    temp.x = p.x
    temp.y = p.y
    temp.z = p.z
    self.constants.cam_pos = temp

end

function light_and_shadows.render_shadows(self)

    render.set_projection(self.light_projection)
    render.set_view(self.light_transform)
    render.set_viewport(0, 0, BUFFER_RESOLUTION, BUFFER_RESOLUTION)

    render.set_depth_mask(true)
    render.set_depth_func(render.COMPARE_FUNC_LEQUAL)
    render.enable_state(render.STATE_DEPTH_TEST)
    render.disable_state(render.STATE_BLEND)
    render.disable_state(render.STATE_CULL_FACE)

    render.set_render_target(self.shadowmap_buffer, { transient = {render.BUFFER_DEPTH_BIT} })
    render.clear({[render.BUFFER_COLOR_BIT] = vmath.vector4(0,0,0,1), [render.BUFFER_DEPTH_BIT] = 1})
    render.enable_material("shadow")
    --  All objects in render list taged as "shadow" will change their material to "shadow.material"
    --  to cast shadows into shadow map texture. This texture will be enabled to all objects at the next render pass.
    render.draw(self.shadow_pred)
    render.disable_material()
    render.set_render_target(render.RENDER_TARGET_DEFAULT)
end

function light_and_shadows.update(self)
    light_and_shadows.update_light(self)
    if light_and_shadows.shadow_quality < 3 then
        light_and_shadows.render_shadows(self)
    end
end

return light_and_shadows