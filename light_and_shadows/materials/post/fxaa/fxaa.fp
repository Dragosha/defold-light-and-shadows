#version 140

in mediump vec2 var_texcoord0;
uniform mediump sampler2D tex0;

out vec4 out_fragColor;
#include "/light_and_shadows/materials/post/fxaa/fxaa.glsl"

void main()
{
    out_fragColor = textureFXAA(tex0, var_texcoord0.xy);
}

