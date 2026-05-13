#version 140

in mediump vec2 var_texcoord0;
uniform mediump sampler2D tex0;
uniform mediump sampler2D tex1;
uniform mediump sampler2D depth;

uniform fs_uniforms
{
    highp vec4 dof;
};

out vec4 out_fragColor;

#include "/light_and_shadows/materials/post/fxaa/fxaa.glsl"

void main()
{
    // regular color texture (render target)
    vec3 color = textureFXAA(tex0, var_texcoord0.xy).rgb;
    // blured render target
    vec3 blured = texture(tex1, var_texcoord0).rgb;
    // depth buffer texture
    float z = texture(depth, var_texcoord0).r;
    float near_z = dof.x;
    float far_z = dof.y;
    float cam_z = dof.z;
    float _focus_range = dof.w;
    float coef = cam_z / (far_z - near_z); // normalize focus distance

    // Linearized Depth Buffer Values for Depth of Field
    float d = (2.0 * near_z) / (far_z + near_z - z * (far_z - near_z));

    // Circle of Confusion
    float focus_distance = coef * 1.75;
    float focus_range = coef * _focus_range;
    float coc = (d - focus_distance) / focus_range;
    coc = abs(clamp(coc, -1, 1));
    
    // d =  abs(d*d -.5) * 2. - coef;

    // DEBUG: 
    // if (var_texcoord0.x > 0.75) 
    //     out_fragColor = vec4(vec3(coc), 1.);
    // else
        out_fragColor = vec4(mix(color, blured, clamp(coc, 0., 1.0)), 1.);


}

