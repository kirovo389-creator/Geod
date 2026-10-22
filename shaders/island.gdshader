shader_type spatial;
render_mode specular_disabled;

varying vec3 island_normal;

void vertex() {
	island_normal = NORMAL;
}

void fragment() {
	float top_face = smoothstep(-0.08, 0.72, island_normal.y);
	float grain = sin(UV.x * 42.0 + sin(UV.y * 25.0)) * 0.025;
	float striation = sin(UV.y * 70.0 + UV.x * 11.0) * 0.018;
	vec3 grass_light = vec3(0.24, 0.55, 0.32);
	vec3 grass_dark = vec3(0.10, 0.34, 0.22);
	vec3 stone = vec3(0.25, 0.31, 0.39);
	vec3 grass = mix(grass_dark, grass_light, clamp(0.55 + grain * 5.0, 0.0, 1.0));
	vec3 cliff = stone + vec3(striation);
	ALBEDO = mix(cliff, grass, top_face);
	ROUGHNESS = 0.94;
}
