local light_and_shadows = {}

local constants = require "light_and_shadows.constants"

local top = vmath.vector3(0, 1, 0)
local v0 = vmath.vector4(0, 0, 0, 0) -- zero vector4

-- true - on
-- false - off / no shadow cast
light_and_shadows.shadow = true

-- Turns On | Off upscale render target. 
-- If ‘on’ all the objects are first rendered to a render target with a size no larger 
-- than specified in the project settings, then this entire render target is placed on the screen with linear scaling. 
light_and_shadows.upscale = false

local BUFFER_RESOLUTION = 2048 -- Size of shadow map. Select value from: 1024/2048/4096. More is better quality.

-- Projection resolution of shadow map to the game world. Smaller size is better shadow quality,
-- but shadows will cast only around the screen center (or a point that camera looks at).
-- This value also depends on camera zoom. Feel free to adjust it.
local PROJECTION_RESOLUTION = 400 

local rt_list = {}
light_and_shadows.rt_list = rt_list

function light_and_shadows.render_target(name, w, h)
    local already_rt = rt_list[name]
    if already_rt and already_rt.w == w and already_rt.h == h then
        -- nothing changed
        return already_rt
    elseif already_rt then
        -- rt is already created, but size is changing. Fix bit.
        already_rt.w = w
        already_rt.h = h
        render.set_render_target_size(already_rt.rt, w, h)
        -- pprint(already_rt)
        return already_rt
    end

    --otherwise create a new RT 

    local color_params = {
        format     = graphics.TEXTURE_FORMAT_RGBA,
        width      = w,
        height     = h,
        min_filter = graphics.TEXTURE_FILTER_LINEAR,
        mag_filter = graphics.TEXTURE_FILTER_LINEAR,
        u_wrap     = graphics.TEXTURE_WRAP_CLAMP_TO_EDGE,
        v_wrap     = graphics.TEXTURE_WRAP_CLAMP_TO_EDGE }

        local depth_params = { 
            format        = graphics.TEXTURE_FORMAT_DEPTH,
            width         = w,
            height        = h,
            u_wrap        = graphics.TEXTURE_WRAP_CLAMP_TO_EDGE,
            v_wrap        = graphics.TEXTURE_WRAP_CLAMP_TO_EDGE }

    local rt = render.render_target(name, {[graphics.BUFFER_TYPE_COLOR0_BIT] = color_params, [graphics.BUFFER_TYPE_DEPTH_BIT] = depth_params })
    local new_rt = {rt = rt, w = w, h = h}
    rt_list[name] = new_rt
    return new_rt
end

-- special vector4 for transfer our settings to the shader program
local param = vmath.vector4(0, 0, 0, 0)

function light_and_shadows.init(self)
    -- self.shadowmap_buffer = light_and_shadows.create_depth_buffer(BUFFER_RESOLUTION, BUFFER_RESOLUTION)
    self.shadowmap_buffer = "shadowmap"

    -- Use this for directional lights
    local proj_w = PROJECTION_RESOLUTION
    local proj_h = PROJECTION_RESOLUTION
    self.light_projection = vmath.matrix4_orthographic(-proj_w/2, proj_w/2, -proj_h/2, proj_h/2, -500, 500)
    -- self.light_projection = vmath.matrix4_perspective(3.141592/2, 1, 1, 1000)

    self.constants = render.constant_buffer()
    self.constants.lights = {}
    self.constants.colors = {}
    self.constants.directions = {}
    self.constants.param = param

    self.bias_matrix    = vmath.matrix4()
    self.bias_matrix.c0 = vmath.vector4(0.5, 0.0, 0.0, 0.0)
    self.bias_matrix.c1 = vmath.vector4(0.0, 0.5, 0.0, 0.0)
    self.bias_matrix.c2 = vmath.vector4(0.0, 0.0, 0.5, 0.0)
    self.bias_matrix.c3 = vmath.vector4(0.5, 0.5, 0.5, 1.0)

    -- self.upscale_rt = {rt = "upscale"}
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
    -- In fragment shader include (fun.glsl) change arrays size here:
    -- #define LIGHT_COUNT 16
    --                     ^^ 
    -- ...
    for i = 1, 8 do
        local l = constants.lights[i]
        if l then
            self.constants.lights[i] = constants.lights[i].position or v0
            self.constants.colors[i] = constants.lights[i].color or v0
            self.constants.directions[i] = constants.lights[i].direction or v0
        else
            self.constants.lights[i] = v0
            self.constants.colors[i] = v0
            self.constants.directions[i] = v0
        end
    end

    -- Setup an ambient and a fog constants
    if constants.ambient then self.constants.ambient = constants.ambient end
    if constants.fog_color then self.constants.fog_color = constants.fog_color end
    if constants.fog then self.constants.fog = constants.fog end
    if constants.tint then self.constants.tint = constants.tint end

    if light_and_shadows.shadow then
        local pos_light = constants.cam_look_at_position + sun
        self.light_transform = vmath.matrix4_look_at(pos_light, constants.cam_look_at_position, top)
        local mtx_light = self.bias_matrix * self.light_projection * self.light_transform
        self.constants.mtx_light = mtx_light
    end
    
    if self.bias then self.constants.b = self.bias end

    -- Setup camera world position uniform constant (vector4)
    -- It's used in shader to calculate speculars by phong model.
    self.constants.cam_pos = constants.cam_position
    -- set param.y as shader iformation do we need to cast shadow or not
    -- > 0 - off
    -- 0 - on (default value) 
    param.y = light_and_shadows.shadow and 0 or 1
    self.constants.param = param
    -- print(self.constants.param, light_and_shadows.shadow)

end

local clear_buffers = {[render.BUFFER_COLOR_BIT] = vmath.vector4(1, 1, 1, 1), [render.BUFFER_DEPTH_BIT] = 1}
function light_and_shadows.render_shadows(self)

    -- Setup our 'shadow' camera view and projection.
    render.set_projection(self.light_projection)
    render.set_view(self.light_transform)
    render.set_viewport(0, 0, BUFFER_RESOLUTION, BUFFER_RESOLUTION)

    render.set_depth_mask(true)
    render.set_depth_func(render.COMPARE_FUNC_LEQUAL)
    render.enable_state(render.STATE_DEPTH_TEST)
    render.disable_state(render.STATE_BLEND)
    render.disable_state(render.STATE_CULL_FACE)

    -- Set render target to shadowmap
    render.set_render_target(self.shadowmap_buffer, { transient = {render.BUFFER_DEPTH_BIT} })
    render.clear(clear_buffers)
    -- Calculate frustum matrix to cut invisible objects from shadow cast
    local frustum = self.light_projection * self.light_transform
    
    --  All objects in render list taged as "shadow" will change their material to "shadow.material"
    --  to cast shadows into shadow map texture. This texture will be enabled to all objects at the next render pass.
    render.enable_material("shadow", {frustum = frustum, frustum_planes = render.FRUSTUM_PLANES_ALL})
        render.draw(self.predicates.shadow)
        render.disable_material()
    -- Separate a world and a local material objects to different render pass.
    render.enable_material("shadow_local", {frustum = frustum, frustum_planes = render.FRUSTUM_PLANES_ALL})
        render.draw(self.predicates.shadow_local)
        render.disable_material()
    render.enable_material("shadow_instanced", {frustum = frustum, frustum_planes = render.FRUSTUM_PLANES_ALL})
        render.draw(self.predicates.shadow_instanced)
        render.disable_material()    
    -- Reset render target
    render.set_render_target(render.RENDER_TARGET_DEFAULT)
end

-- 
-- local common    = require 'helper.common'
light_and_shadows.zoom = 1
function light_and_shadows.update(self)
    light_and_shadows.update_light(self)
    if light_and_shadows.shadow then
        light_and_shadows.render_shadows(self)
    end
    
    if light_and_shadows.upscale then
        local window_width = render.get_window_width()
        local window_height = render.get_window_height()
        local zoom = math.max(window_width / render.get_width(), window_height / render.get_height())
        -- common.zoom = zoom
        light_and_shadows.zoom = zoom
        local w = window_width / zoom
        local h = window_height / zoom
        self.upscale_rt = light_and_shadows.render_target('upscale_rt', w, h)
        -- print(zoom, w, h)
    else
        -- common.zoom = 1
        light_and_shadows.zoom = 1
    end
    
end

local IDENTITY = vmath.matrix4()
-- Draw our RT to Default render surface
function light_and_shadows.draw_upscaled(self)
    local window_width = render.get_window_width()
    local window_height = render.get_window_height()

    -- draw!
    -- render.disable_state(graphics.STATE_BLEND)
    render.set_viewport(0, 0, window_width, window_height)
    render.set_view(IDENTITY)
    render.set_projection(IDENTITY)
    render.enable_texture("tex0", self.upscale_rt.rt)
    render.draw(self.predicates.upscale)
    render.disable_texture("tex0")
    -- render.enable_state(graphics.STATE_BLEND)
end

return light_and_shadows