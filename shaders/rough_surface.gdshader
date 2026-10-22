shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.34, 0.26, 0.18, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.9;
uniform float noise_scale : hint_range(0.5, 32.0) = 10.0;
uniform float wear_strength : hint_range(0.0, 0.5) = 0.12;
uniform float grain_strength : hint_range(0.0, 0.3) = 0.05;

varying vec3 world_pos;

float hash31(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash31(i + vec3(0.0, 0.0, 0.0));
	float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(i + vec3(1.0, 1.0, 1.0));
	float x00 = mix(n000, n100, f.x);
	float x10 = mix(n010, n110, f.x);
	float x01 = mix(n001, n101, f.x);
	float x11 = mix(n011, n111, f.x);
	return mix(mix(x00, x10, f.y), mix(x01, x11, f.y), f.z);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float fine_noise = noise3(world_pos * noise_scale);
	float broad_noise = noise3(world_pos * 2.1);
	float wear_noise = noise3(world_pos * 0.38);
	float worn = smoothstep(0.40, 0.82, wear_noise) * wear_strength;
	float grain = sin(world_pos.z * 15.0 + fine_noise * 5.0) * grain_strength;
	float variation = 0.74 + fine_noise * 0.31 + broad_noise * 0.12 + grain - worn;
	ALBEDO = base_color.rgb * variation;
	ROUGHNESS = clamp(roughness + fine_noise * 0.07, 0.50, 1.0);
	METALLIC = 0.0;
}
