#version 140

in vec3 var_texcoord0;

uniform samplerCube	cubemap;

out vec4 out_fragColor;

void main() {
	out_fragColor = vec4(texture(cubemap, var_texcoord0).rgb, 1.0);

}
