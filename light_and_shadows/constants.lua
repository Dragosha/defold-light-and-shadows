local clear_color       = vmath.vector4(0.1, 0.1, 0.5, 1)
local fog_color         = vmath.vector4(0.1, 0.1, 0.5, 1)
local fog               = vmath.vector4(20, 120, 1, 0)
local ambient_default   = vmath.vector4(0.1, 0.1, 0.1, 1)

-- Special module to access light options in renderscript.
-- Renderscript is going to forward this values into shader uniform constants.
return {
    clear_color = clear_color,
	fog = fog,
	ambient = ambient_default,
	fog_color = fog_color,
    -- List of light sources. Their world position and colors.
    -- v0 is a zero vector4. This value will be assigned in case if there are no sources, or amount of sources less 16 (max in demo).
    -- "Lights" is an indices array. Only first 16 (max in this demo) sources will be used in shader.
    lights = {
        -- {position = v0, color = v0, distance = 1, power = 1},
    },

    cam_look_at_position = vmath.vector3(0, 0, 0),
    sun_position = vmath.vector4(-10, 10, 9, 0),
    sun_color = vmath.vector4(0.75, 0.75, 0.5, 0),
    shadow_color = vmath.vector4(0.25, 0.25, 0.5, 0)
}