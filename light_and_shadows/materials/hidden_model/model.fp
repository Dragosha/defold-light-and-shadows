#version 140

out vec4 out_fragColor;

uniform fs_uniforms
{
    mediump vec4 tint;
};

void main()
{
    out_fragColor = vec4(tint.xyz * tint.w, tint.w);
}

