// Rotated Grid Super-Sampling (RGSS)

#ifdef GL_OES_standard_derivatives
#extension GL_OES_standard_derivatives : enable
#endif

// Derivative functions are available on:
// - OpenGL (desktop).
// - OpenGL ES 3.0, WebGL 2.0.
// - OpenGL ES 2.0, WebGL 1.0, if the extension GL_OES_standard_derivatives is enabled.
#if !defined(GL_ES) || __VERSION__ >= 300 || defined(GL_OES_standard_derivatives)
// Rotated grid UV offsets
const mediump vec2 rgss_uv_offsets = vec2(0.125, 0.375);

mediump vec4 rgss_tex2D(mediump sampler2D texture_sampler, highp vec2 uv, mediump float bias)
{
    // Per pixel partial derivatives
    mediump vec2 dx = dFdx(uv);
    mediump vec2 dy = dFdy(uv);

    // Supersampled using 2x2 rotated grid
    mediump vec4 col = texture(texture_sampler, vec2(uv + rgss_uv_offsets.x * dx + rgss_uv_offsets.y * dy), bias);
    col += texture(texture_sampler, vec2(uv - rgss_uv_offsets.x * dx - rgss_uv_offsets.y * dy), bias);
    col += texture(texture_sampler, vec2(uv + rgss_uv_offsets.y * dx - rgss_uv_offsets.x * dy), bias);
    col += texture(texture_sampler, vec2(uv - rgss_uv_offsets.y * dx + rgss_uv_offsets.x * dy), bias);

    col *= 0.25;

    return col;
}
#else
// A fallback in the case of derivatives lack
mediump vec4 rgss_tex2D(mediump sampler2D texture_sampler, highp vec2 uv, mediump float bias)
{
    return texture(texture_sampler, uv, bias);
}
#endif