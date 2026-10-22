shader_type spatial;
render_mode unshaded, cull_back;

uniform vec4 crystal_color : source_color = vec4(0.06, 0.72, 0.95, 1.0);
uniform vec4 crystal_highlight : source_color = vec4(0.62, 0.98, 1.0, 1.0);

void fragment() {
	float pulse = 0.72 + 0.28 * sin(TIME * 2.4);
	float facet = 0.88 + 0.12 * sin(UV.x * 31.0 + TIME * 0.55);
	float gradient = clamp(UV.y + sin(TIME * 1.35) * 0.06, 0.0, 1.0);
	vec3 tint = mix(crystal_color.rgb, crystal_highlight.rgb, smoothstep(0.05, 0.96, gradient));
	ALBEDO = tint * facet;
	EMISSION = tint * (0.75 + 1.1 * pulse);
	ROUGHNESS = 0.22;
}
