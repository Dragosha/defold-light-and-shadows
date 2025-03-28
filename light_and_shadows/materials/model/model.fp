varying highp vec4 var_position;
varying highp vec3 var_normal;
varying highp vec4 var_view_pos;
varying mediump vec2 var_texcoord0;
varying highp vec4 var_texcoord0_shadow;
varying highp mat4 vmtx_view;

uniform lowp sampler2D tex0;
uniform lowp sampler2D tex1;

uniform lowp vec4 tint;
uniform lowp vec4 ambient;
uniform lowp vec4 fog_color;
uniform lowp vec4 fog;
uniform highp vec4 cam_pos;
uniform mediump vec4 param;

uniform lowp vec4 color0;
uniform highp vec4 light;
uniform highp vec4 shadow_color;

#define LIGHT_COUNT 16
uniform highp vec4 lights[LIGHT_COUNT];
uniform highp vec4 colors[LIGHT_COUNT];

#include "/light_and_shadows/materials/fun.glsl"
#include "/light_and_shadows/materials/fog_fun.glsl"

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    vec4 color = texture2D(tex0, var_texcoord0.xy) * tint_pm;
    if(color.a < 0.2) discard;

    // Diffuse light calculations
    vec3 view_dir = normalize((cam_pos - var_position).xyz);

    vec3 diff_light = vec3(0.0);
    for (int i = 0; i < LIGHT_COUNT; ++i) {
        float power = colors[i].w;
        if (power > 0.0) {
            // vec3 light_color, float power, vec3 light_position, vec3 position, vec3 snormal, float specular, vec3 view_dir
            diff_light += point_light2(colors[i].xyz, power, lights[i].xyz, var_position.xyz, var_normal, 0.2, view_dir);
        }
    }

    // Shadow map
    vec4 depth_proj = var_texcoord0_shadow / var_texcoord0_shadow.w;
    float shadow = shadow_calculation(depth_proj.xyzw, param);
    vec3 shadow_color = shadow_color.xyz * shadow;

    // Direct light minus shadow
    diff_light += direct_light(color0.xyz, light.xyz, var_position.xyz, var_normal, shadow_color);
    diff_light += vec3(ambient.xyz);
    diff_light = clamp(diff_light, 0.0, ambient.w);
    vec3 frag_color  = color.rgb * diff_light ;

    // Add the fog
    frag_color = add_fog(frag_color, var_view_pos.z, fog.x, fog.y, fog_color.rgb*color.a, fog_color.a);

    gl_FragColor = vec4(frag_color, color.a);
}

