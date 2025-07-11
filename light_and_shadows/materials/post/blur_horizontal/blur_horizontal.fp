#version 140

in mediump vec2 var_texcoord0;

uniform mediump sampler2D DIFFUSE_TEXTURE;

uniform fs_uniforms
{
    mediump vec4 resolution; // x - texture width, y - texture height, w - blur power factor
    mediump vec4 direct;
};
out vec4 out_fragColor;

vec2 rand(vec2 co)
{
    return vec2(fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453),
    fract(sin(dot(co.yx ,vec2(12.9898,78.233))) * 43758.5453)) * 0.00047;
}
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

void main()
{

    float texel_size_x = 1.0 / resolution.x;
    float texel_size_y = 1.0 / resolution.y;
    vec3 target = vec3(0., 0., 0.);
    for (int x = -4; x <= 4; ++x)
    {
        vec2 uv = var_texcoord0 + vec2(x,x) * vec2(resolution.w*direct.x * texel_size_x, resolution.w*direct.y * texel_size_y);
        int index = int(16.0*random(gl_FragCoord.xyy, x+4))%16;
        vec3 rgb = texture(DIFFUSE_TEXTURE, uv + poissonDisk16[index]/300.).rgb;
        target += rgb;
     }
    target /= 9.0;
    out_fragColor = vec4(target, 1.);
}

