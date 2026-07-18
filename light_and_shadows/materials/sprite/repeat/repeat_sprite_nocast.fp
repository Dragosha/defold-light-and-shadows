#version 140

in mediump vec2 var_texcoord0;
in highp vec3 var_normal;
in highp vec4 var_position;
in highp vec4 var_view_position;
in highp vec4 var_texcoord0_shadow;

in highp vec2 var_boo;
in highp vec4 var_uv;
in highp vec4 var_repeat;

out vec4 out_fragColor;

uniform mediump sampler2D tex0;
uniform mediump sampler2D tex1;

#include "/light_and_shadows/materials/fun.glsl"
#include "/light_and_shadows/materials/fog_fun.glsl"

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    mediump vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    // Calculate the final UV coord based on local fragment position and texture UV space.
    // float ux = mod(var_boo.x * var_repeat.x, 1.);
    // float uy = mod(var_boo.y * var_repeat.y, 1.);
    float u = var_boo.x * var_repeat.x - floor(var_boo.x * var_repeat.x);
    float v = var_boo.y * var_repeat.y - floor(var_boo.y * var_repeat.y);
    // it looks like the V coordinate axis in atlas space and shader space are in opposite directions.
    vec2 uv = vec2( mix(var_uv.x, var_uv.z, u), mix(var_uv.y, var_uv.w, 1. - v) );
    vec4 color = texture(tex0, uv) * tint_pm;
    // if(color.a < 0.1) discard;

// Editor does not support Lights and Shadows previews yet, so ignore it.
#ifdef EDITOR
    out_fragColor = color;
#else

    // Diffuse light calculations
    vec3 frag_color  = color.rgb * diffuse_light();

    // Add the fog
    frag_color = add_fog(frag_color, var_view_position.z, fog.x, fog.y, fog_color.rgb*color.a, fog_color.a);

    out_fragColor = vec4(frag_color, color.a);
#endif
}
