#version 140

in highp vec4 var_position;
in highp vec4 var_view_position;
in mediump vec2 var_texcoord0;

out vec4 out_fragColor;

uniform mediump sampler2D tex0;

uniform fs_uniforms
{
    mediump vec4 tint;
    mediump vec4 fog_color;
    mediump vec4 fog;
    mediump vec4 ambient;
    mediump vec4 color0;
};

#include "/light_and_shadows/materials/fog_fun.glsl"

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    vec4 color = texture(tex0, var_texcoord0.xy) * tint_pm;
    if(color.a < 0.2) discard;
    vec3 frag_color  = color.rgb * (ambient.xyz + color0.xyz) * .5;

    // Add the fog
    frag_color = add_fog(frag_color, var_view_position.z, fog.x, fog.y, fog_color.rgb*color.a, fog_color.a);

    out_fragColor = vec4(frag_color, color.a);
}

