varying highp vec2 var_texcoord0;
uniform highp sampler2D tex0;

vec4 float_to_rgba( float v )
{
    vec4 enc = vec4(1.0, 255.0, 65025.0, 16581375.0) * v;
    enc      = fract(enc);
    enc     -= enc.yzww * vec4(1.0/255.0, 1.0/255.0, 1.0/255.0, 0.0);
    return enc;
}

void main()
{
    vec4 color = texture2D(tex0, var_texcoord0.xy);
    if(color.a < 0.1) discard;
    gl_FragColor = float_to_rgba(gl_FragCoord.z);
    // gl_FragColor = vec4(gl_FragCoord.z);
}
