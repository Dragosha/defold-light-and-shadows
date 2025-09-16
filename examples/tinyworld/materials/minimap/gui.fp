#version 140

in mediump vec2 var_texcoord0;
in mediump vec4 var_color;

out vec4 out_fragColor;

uniform mediump sampler2D texture_sampler;

void main()
{
    vec4 color = texture(texture_sampler, var_texcoord0.xy) * var_color;

    vec3 final = vec3(0.);
    float mask = color.r;
    
    if (color.b > 0.) final = vec3(0.5) * mask;
    if (color.g > 0.) final = vec3(1., 1., 0.);
    final += vec3(0.3 * mask);


    out_fragColor = vec4(final, 1.0);
}
