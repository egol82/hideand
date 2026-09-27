shader_type spatial;
render_mode specular_schlick_ggx;
varying vec3 world_position;
uniform vec4 base : source_color = vec4(0.73,0.58,0.40,1.0);
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p = world_position.xz;
	float row = floor(p.y / 0.62);
	vec2 cell = vec2(p.x / 2.8 + mod(row,2.0)*0.5, p.y / 0.62);
	vec2 f = fract(cell);
	vec2 width = max(fwidth(cell),vec2(0.002));
	vec2 border = smoothstep(vec2(0.006),vec2(0.006)+width,min(f,1.0-f));
	float joint = min(border.x,border.y);
	float variation = sin(floor(cell.x)*17.0+row*9.0)*0.025;
	float grain = sin(p.y*41.0+sin(p.x*2.2)*0.65)*0.006;
	ALBEDO = base.rgb * (0.975+variation+grain) * mix(0.70,1.0,joint);
	ROUGHNESS = 0.67;
	SPECULAR = 0.26;
}
