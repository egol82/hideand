shader_type spatial;
render_mode diffuse_burley;
uniform vec4 tint_a : source_color = vec4(0.82,0.74,0.64,1.0);
uniform vec4 tint_b : source_color = vec4(0.75,0.66,0.54,1.0);
uniform vec2 repeat_tiles = vec2(20.0,16.0);
uniform bool carpet = false;
void fragment() {
	vec2 uv = UV * repeat_tiles;
	vec2 cell = floor(uv);
	vec2 f = fract(uv);
	float checker = mod(cell.x+cell.y,2.0);
	float seam = smoothstep(0.018,0.038,min(min(f.x,1.0-f.x),min(f.y,1.0-f.y)));
	vec3 base = mix(tint_a.rgb,tint_b.rgb,checker*0.72);
	float weave = sin(UV.x*1800.0)*sin(UV.y*1800.0)*0.010;
	ALBEDO = carpet ? base*(0.98+weave) : base*mix(0.77,1.0,seam);
	ROUGHNESS = carpet ? 0.94 : 0.74;
	SPECULAR = 0.24;
}
