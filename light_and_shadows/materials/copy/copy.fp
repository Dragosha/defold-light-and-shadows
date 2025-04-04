varying mediump vec2 var_texcoord0;
uniform lowp sampler2D tex0;

void main()
{
    vec3 color = texture2D(tex0, var_texcoord0).rgb;
    // color = floor(color * 3.) / 3.; // zx spectrum
    gl_FragColor = vec4(color, 1.);

}

