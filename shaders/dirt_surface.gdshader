shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;

uniform vec4 dirt_color : source_color = vec4(0.24, 0.14, 0.08, 1.0);
uniform float clean_progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float wobble = sin(UV.x * 23.0 + sin(UV.y * 17.0)) * 0.06;
	float radius = length(vec2(uv.x * (1.0 + wobble), uv.y * (0.88 - wobble)));
	float edge = smoothstep(1.0, 0.62, radius);
	float grain = 0.82 + 0.18 * sin(UV.x * 87.0) * sin(UV.y * 71.0);
	float mask = clamp(edge * grain, 0.0, 1.0);
	ALBEDO = dirt_color.rgb * (0.84 + 0.16 * grain);
	ROUGHNESS = 0.98;
	ALPHA = mask * (1.0 - clean_progress);
}
