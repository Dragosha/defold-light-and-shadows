#version 140

in highp vec4 var_position;
in highp vec3 var_normal;
in highp vec4 var_view_position;
in mediump vec2 var_texcoord0;
in highp vec4 var_texcoord0_shadow;

out vec4 out_fragColor;

uniform mediump sampler2D tex0;
uniform mediump sampler2D tex1;
uniform mediump sampler2D fow;

uniform fs_uniforms2
{
    highp vec4 map;
};

#include "/light_and_shadows/materials/fun.glsl"
#include "/light_and_shadows/materials/fog_fun.glsl"
// #include "/examples/tinyworld/materials/rgss.glsl"


float f_rand(vec2 co)
{
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    vec4 color = texture(tex0, var_texcoord0.xy) * tint_pm;
    // vec4 color = rgss_tex2D(tex0, var_texcoord0.xy, -1.0) * tint_pm;
    if(color.a < 0.9) discard;

// Editor does not support Lights and Shadows previews yet, so ignore it.
#ifdef EDITOR
    out_fragColor = color;
#else 
    // Diffuse light calculations
    vec3 diff_light = diffuse_light(ambient.xyz);

    // Shadow map
    vec3 minus_color = vec3(0.);
    if(shadow_color.w > 0.) // on
    {
        vec4 depth_proj = var_texcoord0_shadow / var_texcoord0_shadow.w;
        float shadow = shadow_calculation(depth_proj.xyzw);
        minus_color = shadow_color.xyz * shadow;
    };

    // Direct light minus shadow
    diff_light += direct_light(color0.xyz, light.xyz, var_position.xyz, var_normal, minus_color);
    diff_light = clamp(diff_light, 0.0, ambient.w);

    if(color.a < 1.0)
    { 
        // SELF EMISSIVE if alfa < 1.0
        diff_light = vec3(1.0);
    };
    vec3 frag_color  = color.rgb * diff_light;

    // Add the fog
    frag_color = add_fog(frag_color, var_view_position.z, fog.x, fog.y, fog_color.rgb*color.a, fog_color.a);

    vec2 fow_uv = vec2(0.5 + (var_position.x / map.z)/map.x, 0.5 +(var_position.z / map.z)/map.y);
    vec4 var_fog_of_war = texture(fow, fow_uv );
    if (fow_uv.x<0.0) var_fog_of_war.r = 0.0;
    if (fow_uv.x>1.0) var_fog_of_war.r = 0.0;
    if (fow_uv.y<0.0) var_fog_of_war.r = 0.0;
    if (fow_uv.y>1.0) var_fog_of_war.r = 0.0;


    float chess = 1.0;
            if (mod(floor(gl_FragCoord.y * .25), 2.) > 0.1)
            {
            if (mod(floor(gl_FragCoord.x * .25), 2.) > 0.1)
                chess = 0.;
            }
            else 
            {
            if (mod(floor(gl_FragCoord.x * .25), 2.) < 0.1)
                chess = 0.;
            }

    // vec3 fw = fog_color.xyz - vec3(.15 * ((var_position.y-8.)/32.)* f_rand(floor(gl_FragCoord.xy / 4.)) ) ;
    // float rnd = f_rand(floor(gl_FragCoord.xy / 4.));
    float height = ((var_position.y-8.)/64.);
    vec3 fw = fog_color.xyz - vec3(.1 * chess * height);// + vec3(.025*rnd);
    // (fog_color.xyz - vec3(clamp((var_position.y-8.)/32., 0., .05)))
    out_fragColor = vec4(frag_color * (var_fog_of_war.r) + fw*(1.0 - var_fog_of_war.r), color.a);
#endif
}

