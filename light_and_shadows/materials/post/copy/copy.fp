#version 140

in mediump vec2 var_texcoord0;
uniform mediump sampler2D tex0;

out vec4 out_fragColor;

void main()
{
    vec3 color = texture(tex0, var_texcoord0).rgb;
    // color = floor(color * 3.) / 3.; // zx spectrum
    out_fragColor = vec4(color, 1.);

}

