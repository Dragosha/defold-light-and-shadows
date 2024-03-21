varying highp vec4 var_position;
varying highp vec3 var_normal;
varying highp vec4 var_view_pos;
varying mediump vec2 var_texcoord0;
varying highp mat4 vmtx_view;

uniform lowp sampler2D tex0;

uniform lowp vec4 tint;
uniform lowp vec4 ambient;
uniform lowp vec4 fog_color;
uniform lowp vec4 fog;
uniform highp vec4 cam_pos;

uniform lowp vec4 color0;
uniform highp vec4 light;
uniform highp vec4 shadow_color;

#define LIGHT_COUNT 8
uniform highp vec4 lights[LIGHT_COUNT];
uniform highp vec4 colors[LIGHT_COUNT];

// Point light short version
vec3 point_light(vec3 light_color, float power, vec3 light_position, vec3 position, vec3 vnormal)
{
    vec3 dist = light_position - position;
    vec3 direction = vec3(normalize(dist));
    float d = length(dist);
    vec3 diffuse = light_color * max(dot(vnormal, direction), 0.05) * (1.0/(1.0 + d*power + 2.0*d*d*power*power));
    return diffuse;
}

// SUN! DIRECT LIGHT
vec3 direct_light(vec3 light_color, vec3 light_position, vec3 position, vec3 vnormal)
{
    vec3 dist = light_position;
    vec3 direction = normalize(dist);
    float n = max(dot(vnormal, direction), 0.0);
    vec3 diffuse = (light_color) * n;
    return diffuse;
}

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    vec4 color = texture2D(tex0, var_texcoord0.xy) * tint_pm;
    if(color.a < 0.2) discard;

   
    // Diffuse light calculations
    vec3 diff_light = vec3(0.0);
    for (int i = 0; i < LIGHT_COUNT; ++i) {
        float power = colors[i].w;
        if (power > 0.0) {
            diff_light += point_light(colors[i].xyz, power, lights[i].xyz, var_position.xyz, var_normal);
        }
    }
                   
    diff_light += direct_light(color0.xyz, light.xyz, var_position.xyz, var_normal);
    diff_light += vec3(ambient.xyz);
    diff_light = clamp(diff_light, 0.0, ambient.w);
    vec3 frag_color  = color.rgb * diff_light ;

    // Fog
    float dist = abs(var_view_pos.z);
    float fog_max = fog.y;
    float fog_min = fog.x;
    float fog_factor = clamp((fog_max - dist) / (fog_max - fog_min) + fog_color.a, 0.0, 1.0 );
    frag_color = mix(fog_color.rgb, frag_color, fog_factor);

    gl_FragColor = vec4(frag_color, color.a);
}

