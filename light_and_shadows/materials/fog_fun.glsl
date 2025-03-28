// Put functions in this file to use them in shaders
// To get access to the functions, you need to put:
// #include "/my-folder/my-file.glsl"
// in any script using the functions.
// Please consult the manual on how to use this feature!

#ifndef LS_FOGFUN
#define LS_FOGFUN

// Fog
vec3 add_fog(vec3 frag_color, float dist, float fog_min, float fog_max, vec3 fog_color, float density)
{
    float fog_factor = clamp((fog_max - abs(dist)) / (fog_max - fog_min) + density, 0.0, 1.0 );
    return  mix(fog_color, frag_color, fog_factor);
}

#endif // LS_FOGFUN