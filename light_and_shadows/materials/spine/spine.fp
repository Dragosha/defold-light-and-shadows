#version 140

in mediump vec2 var_texcoord0;
in highp vec3 var_normal;
in highp vec4 var_position;
in highp vec4 var_view_position;
in highp vec4 var_texcoord0_shadow;
in mediump vec4 var_color;
in mediump vec3 var_darkcolor;

out vec4 out_fragColor;

uniform mediump sampler2D tex0;
uniform mediump sampler2D tex1;

#include "/light_and_shadows/materials/fun.glsl"
#include "/light_and_shadows/materials/fog_fun.glsl"

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    mediump vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    mediump vec4 color_pm = var_color * tint_pm;
    mediump vec3 darkcolor_pm = var_darkcolor * tint_pm.rgb;

    vec4 color = texture(tex0, var_texcoord0.xy);
    mediump vec3 dark_rgb = (color.aaa - color.rgb) * darkcolor_pm;
    mediump vec3 light_rgb = color.rgb * color_pm.rgb;

    if(param.x > 0. && color.a < param.y) discard;
    
// Editor does not support Lights and Shadows previews yet, so ignore it.
#ifdef EDITOR
    out_fragColor = vec4(dark_rgb + light_rgb, color.a * color_pm.a);
#else 
    // Diffuse light calculations
    vec3 frag_color  = (dark_rgb + light_rgb) * diffuse_light();

    // Add the fog
    frag_color = add_fog(frag_color, var_view_position.z, fog.x, fog.y, fog_color.rgb*color.a, fog_color.a);

    out_fragColor = vec4(frag_color, color.a * color_pm.a);
#endif
}
