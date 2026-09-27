shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float strength : hint_range(0.0, 0.6) = 0.24;
uniform vec4 tint : source_color = vec4(0.12, 0.15, 0.14, 1.0);
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float softness = 1.0 - smoothstep(0.12, 1.0, dot(p,p));
	ALBEDO = tint.rgb;
	ALPHA = softness * softness * strength;
}
