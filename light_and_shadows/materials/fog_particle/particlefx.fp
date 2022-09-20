varying mediump vec2 var_texcoord0;
varying lowp vec4 var_color;

uniform lowp sampler2D texture_sampler;
uniform lowp vec4 tint;
uniform lowp vec4 fog_color;
uniform lowp vec4 fog;
varying highp vec4 var_view_position;
void main()
{
    // Pre-multiply alpha since all runtime textures already are
    lowp vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    vec4 color = texture2D(texture_sampler, var_texcoord0.xy) * var_color * tint_pm;

    vec3 frag_color  = color.rgb;

    // Fog
    float dist = abs(var_view_position.z);
    float fog_max = fog.y;
    float fog_min = fog.x;
    float fog_factor = clamp((fog_max - dist) / (fog_max - fog_min) + fog_color.a, 0.0, 1.0 );
    frag_color = mix(fog_color.rgb*color.a, frag_color, fog_factor);

    gl_FragColor = vec4(frag_color, color.a);
}
