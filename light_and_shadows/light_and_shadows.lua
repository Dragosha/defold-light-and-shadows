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

light_and_shadows.blur = false
light_and_shadows.blur_power = 1

-- To reduce the Peter Panning effect (shadows detaching from objects) in shadow mapping, you need to adjust the shadow bias, a value that offsets the shadow depth.
-- Too high a bias causes Peter Panning, while too low a bias leads to shadow acne.
light_and_shadows.depth_bias = 0.0004

light_and_shadows.max_lights = 8

local BUFFER_RESOLUTION = 2048 -- Size of shadow map. Select value from: 1024/2048/4096. More is better quality.

-- Projection resolution of shadow map to the game world. Smaller size is better shadow quality,
-- but shadows will cast only around the screen center (or a point that camera looks at).
-- This value also depends on camera zoom. Feel free to adjust it.
local PROJECTION_RESOLUTION = 400 

local rt_list = {}
light_and_shadows.rt_list = rt_list

function light_and_shadows.render_target(name, w, h, no_depth)
    local already_rt = rt_list[name]
    if already_rt and already_rt.w == w and already_rt.h == h then
        -- nothing changed
        return already_rt
    elseif already_rt then
        -- rt is already created, but size is changing. Fix it.
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

    local rt = render.render_target(name, {[graphics.BUFFER_TYPE_COLOR0_BIT] = color_params, [graphics.BUFFER_TYPE_DEPTH_BIT] = not no_depth and depth_params or nil })
    local new_rt = {rt = rt, w = w, h = h}
    rt_list[name] = new_rt
    return new_rt
end

-- special vector4 for transfer our settings to the shader program
local param = vmath.vector4(0, 0, 0, 0)

local light_projection
local is_ortho_proj = true

function light_and_shadows.set_orthographic_projection(proj_w, proj_h, near_z, far_z)
    light_projection = vmath.matrix4_orthographic(-proj_w/2, proj_w/2, -proj_h/2, proj_h/2, near_z or -500, far_z or 500)
    is_ortho_proj = true
end
function light_and_shadows.set_perspective_projection(fov, aspect, near_z, far_z)
    light_projection = vmath.matrix4_perspective(fov or (3.14/1.5), aspect or 1, near_z or 50, far_z or 500)
    is_ortho_proj = false
end

function light_and_shadows.init(self)
    -- self.shadowmap_buffer = light_and_shadows.create_depth_buffer(BUFFER_RESOLUTION, BUFFER_RESOLUTION)
    self.shadowmap_buffer = "shadowmap"

    -- Use this for directional lights
    light_and_shadows.set_orthographic_projection(PROJECTION_RESOLUTION, PROJECTION_RESOLUTION, -500, 500)

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
local v4 = vmath.vector4()
local cam_look_at_position = vmath.vector4()

function light_and_shadows.update_light(self)
    -- Direct light
    sun.x = constants.sun_position.x
    sun.y = constants.sun_position.y
    sun.z = constants.sun_position.z
   
    -- Sun position, color and shadow intensity
    if is_ortho_proj then
        self.constants.light = constants.sun_position or v0
    else
        temp.x = constants.sun_position.x - constants.cam_look_at_position.x
        temp.y = constants.sun_position.y - constants.cam_look_at_position.y
        temp.z = constants.sun_position.z - constants.cam_look_at_position.z
        self.constants.light = temp
    end
    -- self.constants.light = constants.sun_position or v0
    self.constants.color0 = constants.sun_color or v0
    --
    constants.shadow_color = constants.shadow_color or v0
    --  Cast shadow or not cast? 1 - yes, 0 - no
    constants.shadow_color.w = light_and_shadows.shadow and 1 or 0
    self.constants.shadow_color = constants.shadow_color

    -- Point lights uniform constants.
    -- Fills light position and color arrays.
    -- 16 simultaneously calculation light sources.
    -- If you need to change this amount of light sources you should to change it in fragment shader as well.
    -- In fragment shader include (fun.glsl) change arrays size here:
    -- #define LIGHT_COUNT 16
    --                     ^^ 
    -- ...
    for i = 1, light_and_shadows.max_lights do
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
        if is_ortho_proj then
            local pos_light = constants.cam_look_at_position + sun
            self.light_transform = vmath.matrix4_look_at(pos_light, constants.cam_look_at_position, top)
        else
            self.light_transform = vmath.matrix4_look_at(sun, sun + constants.sun_dir, top)
        end
        self.frustum = light_projection * self.light_transform
        local mtx_light = self.bias_matrix * self.frustum
        self.constants.mtx_light = mtx_light
    end
    
    if self.bias then self.constants.b = self.bias end

    -- Setup camera world position uniform constant (vector4)
    -- It's used in shader to calculate speculars by phong model.
    self.constants.cam_pos = constants.cam_position
    
    -- v4 uniform uses to pass some important values to shaders program
    self.dt = (self.dt or 0) + 1/60 -- dt
    v4.x = math.sin(self.dt)
    v4.y = math.cos(self.dt)
    v4.z = light_and_shadows.max_lights
    v4.w = light_and_shadows.depth_bias
    self.constants.v4 = v4

    if constants.map then self.constants.map = constants.map end

    -- Camera focus point. Look at this point.
    cam_look_at_position.x = constants.cam_look_at_position.x
    cam_look_at_position.y = constants.cam_look_at_position.y
    cam_look_at_position.z = constants.cam_look_at_position.z
    self.constants.cam_look_at_position = cam_look_at_position
end

local clear_buffers = {[render.BUFFER_COLOR_BIT] = vmath.vector4(1, 1, 1, 1), [render.BUFFER_DEPTH_BIT] = 1}
function light_and_shadows.render_shadows(self)

    -- Setup our 'shadow' camera view and projection.
    render.set_projection(light_projection)
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
    local frustum = self.frustum or (light_projection * self.light_transform)
    
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
    render.enable_material("shadow_instanced_billboard", {frustum = frustum, frustum_planes = render.FRUSTUM_PLANES_ALL})
    render.draw(self.predicates.shadow_instanced_billboard)
    render.disable_material()
    render.enable_material("shadow_instanced_textured", {frustum = frustum, frustum_planes = render.FRUSTUM_PLANES_ALL})
    render.draw(self.predicates.shadow_instanced_textured)
    render.disable_material()
    render.enable_material("shadow_skinned_instanced", {frustum = frustum, frustum_planes = render.FRUSTUM_PLANES_ALL})
        render.draw(self.predicates.shadow_skinned_instanced)
        render.disable_material()
    render.enable_material("shadow_skinned", {frustum = frustum, frustum_planes = render.FRUSTUM_PLANES_ALL})
        render.draw(self.predicates.shadow_skinned)
        render.disable_material() 
    -- Reset render target
    render.set_render_target(render.RENDER_TARGET_DEFAULT)
end

-- 
-- local common    = require 'helper.common'
light_and_shadows.zoom = 1
local resolution = vmath.vector4()
function light_and_shadows.update(self)
    light_and_shadows.update_light(self)
    if light_and_shadows.shadow then
        light_and_shadows.render_shadows(self)
    end
    
    if light_and_shadows.upscale or light_and_shadows.blur then
        local window_width = render.get_window_width()
        local window_height = render.get_window_height()
        local zoom = math.max(window_width / render.get_width(), window_height / render.get_height())
        -- common.zoom = zoom
        light_and_shadows.zoom = zoom
        local w = window_width / zoom
        local h = window_height / zoom
        self.upscale_rt = light_and_shadows.render_target('upscale_rt', w, h)
        resolution.x = w
        resolution.y = h
        resolution.w = light_and_shadows.blur_power
        self.constants.resolution = resolution
        -- print(zoom, w, h)

        if light_and_shadows.blur then
            self.blur_rt = light_and_shadows.render_target("blur_rt", w, h, true)
        end
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

    if  light_and_shadows.blur then
        -- Blur the render target in 2 passes
        render.disable_state(render.STATE_BLEND)
        render.disable_state(render.STATE_DEPTH_TEST)
        render.set_depth_mask(false)
        render.set_view(IDENTITY)
        render.set_projection(IDENTITY)
        render.set_viewport(0, 0, self.blur_rt.w, self.blur_rt.h)
        -- PASS 1 upscale_rt -> blur_rt
        render.set_render_target(self.blur_rt.rt)
        render.enable_material("blur_horizontal")
        render.enable_texture(0, self.upscale_rt.rt, render.BUFFER_COLOR_BIT)
        render.draw(self.predicates.upscale, {constants = self.constants})
        render.disable_texture(0)
        render.disable_material()
        -- PASS 2 blur_rt -> upscale_rt
        render.set_render_target(self.upscale_rt.rt)
        render.enable_material("blur_vertical")
        render.enable_texture(0, self.blur_rt.rt, render.BUFFER_COLOR_BIT)
        render.draw(self.predicates.upscale, {constants = self.constants})
        render.disable_texture(0)
        render.disable_material()
        render.set_render_target(render.RENDER_TARGET_DEFAULT)
    end
    
    -- draw `upscale_rt` to default RT
    -- render.disable_state(graphics.STATE_BLEND)
    render.set_viewport(0, 0, window_width, window_height)
    render.set_view(IDENTITY)
    render.set_projection(IDENTITY)
    render.enable_material("copy")
    render.enable_texture("tex0", self.upscale_rt.rt)
    render.draw(self.predicates.upscale)
    render.disable_texture("tex0")
    render.disable_material()
    render.enable_state(graphics.STATE_BLEND)
end

return light_and_shadows