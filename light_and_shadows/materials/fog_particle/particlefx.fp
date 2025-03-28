varying mediump vec2 var_texcoord0;
varying lowp vec4 var_color;

uniform lowp sampler2D texture_sampler;
uniform lowp vec4 tint;
uniform lowp vec4 fog_color;
uniform lowp vec4 fog;
varying highp vec4 var_view_position;

#include "/light_and_shadows/materials/fog_fun.glsl"

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    lowp vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    vec4 color = texture2D(texture_sampler, var_texcoord0.xy) * var_color * tint_pm;

    vec3 frag_color  = color.rgb;

    // Add the fog
    frag_color = add_fog(frag_color, var_view_position.z, fog.x, fog.y, fog_color.rgb*color.a, fog_color.a);

    gl_FragColor = vec4(frag_color, color.a);
}
