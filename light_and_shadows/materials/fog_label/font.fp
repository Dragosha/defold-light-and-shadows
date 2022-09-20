varying mediump vec2 var_texcoord0;
varying lowp vec4 var_face_color;
varying lowp vec4 var_outline_color;
varying lowp vec4 var_shadow_color;
varying lowp vec4 var_layer_mask;

uniform lowp sampler2D texture_sampler;

uniform lowp vec4 fog_color;
uniform lowp vec4 fog;
varying highp vec4 var_view_position;

void main()
{
    lowp float is_single_layer = var_layer_mask.a;
    lowp vec3 t                = texture2D(texture_sampler, var_texcoord0.xy).xyz;
    float face_alpha           = var_face_color.w * t.x;

    float raw_outline_alpha    = var_outline_color.w * t.y;
    float max_outline_alpha    = (1.0 - face_alpha * is_single_layer);
    float outline_alpha        = min(raw_outline_alpha, max_outline_alpha);

    float raw_shadow_alpha     = var_shadow_color.w * t.z;
    float max_shadow_alpha     = (1.0 - (face_alpha + outline_alpha) * is_single_layer);
    float shadow_alpha         = min(raw_shadow_alpha, max_shadow_alpha);

    lowp vec4 face_color       = var_layer_mask.x * vec4(var_face_color.xyz, 1.0)    * face_alpha;
    lowp vec4 outline_color    = var_layer_mask.y * vec4(var_outline_color.xyz, 1.0) * outline_alpha;
    lowp vec4 shadow_color     = var_layer_mask.z * vec4(var_shadow_color.xyz, 1.0)  * shadow_alpha;

    vec4 frag_color  = face_color + outline_color + shadow_color;

    // Fog
    float dist = abs(var_view_position.z);
    float fog_max = fog.y;
    float fog_min = fog.x;
    float fog_factor = clamp((fog_max - dist) / (fog_max - fog_min) + fog_color.a, 0.0, 1.0 );
    frag_color.rgb = mix(fog_color.rgb*frag_color.a, frag_color.rgb, fog_factor);

    gl_FragColor = frag_color;
}
