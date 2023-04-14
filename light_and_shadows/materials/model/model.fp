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

uniform lowp vec4 color0;
uniform highp vec4 light;
uniform highp vec4 shadow_color;

#define LIGHT_COUNT 16
uniform highp vec4 lights[LIGHT_COUNT];
uniform highp vec4 colors[LIGHT_COUNT];


vec2 rand(vec2 co)
{
    return vec2(fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453),
    fract(sin(dot(co.yx ,vec2(12.9898,78.233))) * 43758.5453)) * 0.00047;
}
// 
float rgba_to_float(vec4 rgba)
{
    return dot(rgba, vec4(1.0, 1.0/255.0, 1.0/65025.0, 1.0/16581375.0));
}
// 
float shadow_calculation(vec4 depth_data)
{
    float depth_bias = 0.0008;
    float shadow = 0.0;
    float texel_size = 1.0 / 2048.0;//textureSize(tex1, 0);
    for (int x = -1; x <= 1; ++x)
    {
        for (int y = -1; y <= 1; ++y)
        {
            vec2 uv = depth_data.st + vec2(x,y) * texel_size;
            vec4 rgba = texture2D(tex1, uv + rand(uv));
            // vec4 rgba = texture2D(tex1, uv);
            float depth = rgba_to_float(rgba);
            // float depth = rgba.x;
            shadow += depth_data.z - depth_bias > depth ? 1.0 : 0.0;
        }
    }
    shadow /= 9.0;

    highp vec2 uv = depth_data.xy;
    if (uv.x<0.0) shadow = 0.0;
    if (uv.x>1.0) shadow = 0.0;
    if (uv.y<0.0) shadow = 0.0;
    if (uv.y>1.0) shadow = 0.0;

    return shadow;
}

float shadow_calculation_mobile(vec4 depth_data)
{
    float depth_bias = 0.0008;
    highp vec2 uv = depth_data.xy;
    // vec4 rgba = texture2D(tex1, uv + rand(uv));
    vec4 rgba = texture2D(tex1, uv);
    float depth = rgba_to_float(rgba);
    // float depth = rgba.x;
    float shadow = depth_data.z - depth_bias > depth ? 1.0 : 0.0;

    if (uv.x<0.0) shadow = 0.0;
    if (uv.x>1.0) shadow = 0.0;
    if (uv.y<0.0) shadow = 0.0;
    if (uv.y>1.0) shadow = 0.0;

    return shadow;
}

// vec3 point_light(vec3 light_color, float power, vec3 light_position, vec3 position, vec3 vnormal)
// {
//     vec3 dist = light_position - position;
//     vec3 direction = vec3(normalize(dist));
//     float d = length(dist);
//     vec3 diffuse = light_color * max(dot(vnormal, direction), 0.05) * (1.0/(1.0 + d*power + 2.0*d*d*power*power));
//     return diffuse;
// }

const float phong_shininess = 16.0;
// const vec3 specular_color = vec3(1.0);
vec3 point_light2(vec3 light_color, float power, vec3 light_position, vec3 position, vec3 vnormal, float specular, vec3 view_dir)
{
    
    vec3 dist = light_position - position;
    vec3 direction = vec3(normalize(dist));
    float d = length(dist);

    vec3 reflect_dir = reflect(-direction, vnormal);
    float spec_dot = max(dot(reflect_dir, view_dir), 0.0);

    float irradiance = max(dot(vnormal, direction), 0.05);
    float attenuation = (1.0/(1.0 + d*power + 2.0*d*d*power*power));
    vec3 diffuse = light_color * irradiance * attenuation;

    // if (irradiance > 0.0) {
    diffuse += irradiance * attenuation * specular * pow(spec_dot, phong_shininess) * light_color; // *specular_color
    // }
    return diffuse;
}

// SUN! DIRECT LIGHT
vec3 direct_light(vec3 light_color, vec3 light_position, vec3 position, vec3 vnormal, vec3 shadow_color)
{
    vec3 dist = light_position;
    vec3 direction = normalize(dist);
    float n = max(dot(vnormal, direction), 0.0);
    vec3 diffuse = (light_color - shadow_color) * n;
    return diffuse;
}

// const float bump = 0.5;
// vec3 get_normal2() 
// {
//     vec3 pos_dx = dFdx(var_position.xyz);
//     vec3 pos_dy = dFdy(var_position.xyz);
//     vec2 tex_dx = dFdx(var_texcoord0.xy);
//     vec2 tex_dy = dFdy(var_texcoord0.xy);
//     vec3 t = normalize(pos_dx * tex_dy.t - pos_dy * tex_dx.t);
//     vec3 b = normalize(-pos_dx * tex_dy.s + pos_dy * tex_dx.s);
//     mat3 tbn = mat3(t, b, var_normal);
//     vec3 n = texture2D(tex2, var_texcoord0.xy).rgb * 2.0 - 1.0;
//     n.xy *= bump;
//     vec3 normal = normalize(tbn * n);
//     // Get world normal from view normal
//     return normal;
//     // return normalize((vec4(normal, 0.0) * vmtx_view).xyz);
// }

// vec3 get_normal()
// {
//     vec3 n = texture2D(tex2, var_texcoord0.xy).rgb * 2.0 - 1.0;
//     n.xy *= bump;
//     vec3 normal = normalize(var_normal + n);
//     return normalize((vec4(normal, 0.0) * vmtx_view).xyz);
// }

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    vec4 color = texture2D(tex0, var_texcoord0.xy) * tint_pm;
    if(color.a < 0.2) discard;

    // vec3 normal_sum = get_normal(); // short normal calculation
    // vec3 normal_sum = get_normal2(); // - full normal calculation
    vec3 normal_sum = var_normal; // no mormal map

    // shadow map
    vec4 depth_proj = var_texcoord0_shadow / var_texcoord0_shadow.w;
    float shadow = shadow_calculation(depth_proj.xyzw);
    vec3 shadow_color = shadow_color.xyz * shadow;

    
    // Diffuse light calculations
    vec3 view_dir = normalize((cam_pos - var_position).xyz);

    vec3 diff_light = vec3(0.0);
    for (int i = 0; i < LIGHT_COUNT; ++i) {
        float power = colors[i].w;
        if (power > 0.0) {
            // vec3 light_color, float power, vec3 light_position, vec3 position, vec3 snormal, float specular, vec3 view_dir
            diff_light += point_light2(colors[i].xyz, power, lights[i].xyz, var_position.xyz, normal_sum, 0.2, view_dir);
        }
    }
                   

    diff_light += direct_light(color0.xyz, light.xyz, var_position.xyz, normal_sum, shadow_color);
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

