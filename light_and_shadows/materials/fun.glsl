// Put functions in this file to use them in shaders
// To get access to the functions, you need to put:
// #include "/my-folder/my-file.glsl"
// in any script using the functions.
// Please consult the manual on how to use this feature!

#ifndef LS_FUN
#define LS_FUN

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

#define USE_PCF_SHADOW
// #define USE_PCF_POISSON_SHADOW
// #define USE_FLAT_SHADOW

#ifdef USE_PCF_SHADOW
//
float shadow_calculation(vec4 depth_data, vec4 param)
{
    if(param.y > 0.) return 0.0; // do not calculate shadow if cast parameter set to disabled.

    float depth_bias = 0.0008;
    float shadow = 0.0;
    float texel_size = 1.0 / 2048.0; //textureSize(tex1, 0);
    int y = 0;
    for (int x = -1; x <= 1; ++x)
    {
        vec2 uv = depth_data.xy + vec2(x,y) * texel_size;
        vec4 rgba = texture2D(tex1, uv + rand(uv));
        float depth = rgba_to_float(rgba);
        shadow += depth_data.z - depth_bias > depth ? 1.0 : 0.0;
    }
    shadow /= 3.0;

    highp vec2 uv = depth_data.xy;
    if (uv.x<0.0) shadow = 0.0;
    if (uv.x>1.0) shadow = 0.0;
    if (uv.y<0.0) shadow = 0.0;
    if (uv.y>1.0) shadow = 0.0;

    return shadow;
}
#endif

#ifdef USE_PCF_POISSON_SHADOW

vec2 poissonDisk[4] = vec2[](
    vec2( -0.94201624, -0.39906216 ),
    vec2( 0.94558609, -0.76890725 ),
    vec2( -0.094184101, -0.92938870 ),
    vec2( 0.34495938, 0.29387760 )
);

vec2 poissonDisk16[16] = vec2[]( 
    vec2( -0.94201624, -0.39906216 ), 
    vec2( 0.94558609, -0.76890725 ), 
    vec2( -0.094184101, -0.92938870 ), 
    vec2( 0.34495938, 0.29387760 ), 
    vec2( -0.91588581, 0.45771432 ), 
    vec2( -0.81544232, -0.87912464 ), 
    vec2( -0.38277543, 0.27676845 ), 
    vec2( 0.97484398, 0.75648379 ), 
    vec2( 0.44323325, -0.97511554 ), 
    vec2( 0.53742981, -0.47373420 ), 
    vec2( -0.26496911, -0.41893023 ), 
    vec2( 0.79197514, 0.19090188 ), 
    vec2( -0.24188840, 0.99706507 ), 
    vec2( -0.81409955, 0.91437590 ), 
    vec2( 0.19984126, 0.78641367 ), 
    vec2( 0.14383161, -0.14100790 ) 
);

// Returns a random number based on a vec3 and an int.
float random(vec3 seed, int i)
{
    vec4 seed4 = vec4(seed,i);
    float dot_product = dot(seed4, vec4(12.9898,78.233,45.164,94.673));
    return fract(sin(dot_product) * 43758.5453);
}

float shadow_calculation(vec4 depth_data, vec4 param)
{

    if(param.y > 0.) return 0.0;

    float depth_bias = 0.0025;
    float shadow = 0.0;
    int y = 0;
    for (int x = 0; x < 8; x++)
    {
        int index = int(16.0*random(gl_FragCoord.xyy, x))%16;

        vec2 uv = depth_data.xy + poissonDisk16[x]/700.0;
        vec4 rgba = texture2D(tex1, uv);
        float depth = rgba_to_float(rgba);
        shadow += depth_data.z - depth_bias > depth ? 1.0 : 0.0;
    }
    shadow /= 8.0;

    highp vec2 uv = depth_data.xy;
    if (uv.x<0.0) shadow = 0.0;
    if (uv.x>1.0) shadow = 0.0;
    if (uv.y<0.0) shadow = 0.0;
    if (uv.y>1.0) shadow = 0.0;

    return shadow;
} 
#endif

#ifdef USE_FLAT_SHADOW
float shadow_calculation(vec4 depth_data, vec4 param)
{
    if(param.y > 0.) return 0.0;
    
    float depth_bias = 0.0008;
    highp vec2 uv = depth_data.xy;
    // vec4 rgba = texture2D(tex1, uv + rand(uv));
    vec4 rgba = texture2D(tex1, uv);
    float depth = rgba_to_float(rgba);
    float shadow = depth_data.z - depth_bias > depth ? 1.0 : 0.0;

    if (uv.x<0.0) shadow = 0.0;
    if (uv.x>1.0) shadow = 0.0;
    if (uv.y<0.0) shadow = 0.0;
    if (uv.y>1.0) shadow = 0.0;

    return shadow;
}
#endif

vec3 point_light(vec3 light_color, float power, vec3 light_position, vec3 position, vec3 vnormal)
{
    vec3 dist = light_position - position;
    vec3 direction = vec3(normalize(dist));
    float d = length(dist);
    vec3 diffuse = light_color * max(dot(vnormal, direction), 0.05) * (1.0/(1.0 + d*power + 2.0*d*d*power*power));
    return diffuse;
}

const float phong_shininess = 8.0;
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

#endif // LS_FUN