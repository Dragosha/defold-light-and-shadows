// FXAA
// Fast Approximate Anti-Aliasing by XOR (https://mini.gmshaders.com/p/gm-shaders-mini-fxaa)
// https://github.com/XorDev/GM_FXAA/blob/main/GM_FXAA/shaders/shd_fxaa/shd_fxaa.fsh

uniform fx_uniforms
{
    mediump vec4 main_rt_resolution; // x - texture width, y - texture height
};


#ifdef GL_OES_standard_derivatives
#extension GL_OES_standard_derivatives : enable
#endif

// Derivative functions are available on:
// - OpenGL (desktop).
// - OpenGL ES 3.0, WebGL 2.0.
// - OpenGL ES 2.0, WebGL 1.0, if the extension GL_OES_standard_derivatives is enabled.
#if !defined(GL_ES) || __VERSION__ >= 300 || defined(GL_OES_standard_derivatives)

//Maximum texel span
#define SPAN_MAX   (8.0)
//These are more technnical and probably don't need changing:
//Minimum "dir" reciprocal
#define REDUCE_MIN (1.0/128.0)
//Luma multiplier for "dir" reciprocal
#define REDUCE_MUL (1.0/32.0)

mediump vec4 textureFXAA(mediump sampler2D tex, highp vec2 uv)
{

    //Texel size (1/resolution)
    mediump vec2 u_texel = vec2(1.0/main_rt_resolution.x, 1.0/main_rt_resolution.y);

    //Sample center and 4 corners
    vec3 rgbCC = texture(tex, uv).rgb;
    vec3 rgb00 = texture(tex, uv+vec2(-0.5,-0.5)*u_texel).rgb;
    vec3 rgb10 = texture(tex, uv+vec2(+0.5,-0.5)*u_texel).rgb;
    vec3 rgb01 = texture(tex, uv+vec2(-0.5,+0.5)*u_texel).rgb;
    vec3 rgb11 = texture(tex, uv+vec2(+0.5,+0.5)*u_texel).rgb;
    
    //Luma coefficients
    const vec3 luma = vec3(0.299, 0.587, 0.114);
    //Get luma from the 5 samples
    float lumaCC = dot(rgbCC, luma);
    float luma00 = dot(rgb00, luma);
    float luma10 = dot(rgb10, luma);
    float luma01 = dot(rgb01, luma);
    float luma11 = dot(rgb11, luma);
    
    //Compute gradient from luma values
    vec2 dir = vec2((luma01 + luma11) - (luma00 + luma10), (luma00 + luma01) - (luma10 + luma11));
    //Diminish dir length based on total luma
    float dirReduce = max((luma00 + luma10 + luma01 + luma11) * REDUCE_MUL, REDUCE_MIN);
    //Divide dir by the distance to nearest edge plus dirReduce
    float rcpDir = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
    //Multiply by reciprocal and limit to pixel span
    dir = clamp(dir * rcpDir, -SPAN_MAX, SPAN_MAX) * u_texel.xy;
    
    //Average middle texels along dir line
    vec4 A = 0.5 * (
        texture(tex, uv - dir * (1.0/6.0)) +
        texture(tex, uv + dir * (1.0/6.0)));
    
    //Average with outer texels along dir line
    vec4 B = A * 0.5 + 0.25 * (
        texture(tex, uv - dir * (0.5)) +
        texture(tex, uv + dir * (0.5)));
        
        
    //Get lowest and highest luma values
    float lumaMin = min(lumaCC, min(min(luma00, luma10), min(luma01, luma11)));
    float lumaMax = max(lumaCC, max(max(luma00, luma10), max(luma01, luma11)));
    
    //Get average luma
    float lumaB = dot(B.rgb, luma);
    //If the average is outside the luma range, using the middle average
    return ((lumaB < lumaMin) || (lumaB > lumaMax)) ? A : B;
}
#else
// A fallback in the case of derivatives lack
mediump vec4 textureFXAA(mediump sampler2D tex, highp vec2 uv)
{
    return texture(tex, uv);
}
#endif