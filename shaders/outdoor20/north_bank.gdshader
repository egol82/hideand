shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// North-only colour on the existing hull. No vertex displacement, extra shell,
// time, world/actor input or transparency: collision and occlusion stay exact.
uniform vec4 mud_color : source_color = vec4(0.51, 0.435, 0.335, 1.0);
uniform vec4 moss_color : source_color = vec4(0.53, 0.62, 0.38, 1.0);
varying vec3 bank_position;

float patch_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float patch_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(patch_hash(cell), patch_hash(cell + vec2(1.0, 0.0)), f.x),
		mix(patch_hash(cell + vec2(0.0, 1.0)), patch_hash(cell + vec2(1.0)), f.x), f.y);
}

void vertex() {
	bank_position = VERTEX;
}

void fragment() {
	vec2 p = bank_position.xz;
	float broad = patch_noise(p * 1.65 + vec2(3.7, -1.8));
	float small = patch_noise(p * 5.0 + vec2(-8.2, 2.3));
	// Irregular fingers descend the bank, with a soft earthy transition.
	float grain = patch_noise(p * 13.0 + vec2(2.4, 7.9));
	float edge = 1.18 + (broad - 0.5) * 0.62 + (small - 0.5) * 0.20 + (grain - 0.5) * 0.055;
	float moss = smoothstep(edge - 0.035, edge + 0.035, bank_position.y);
	float mottling = 0.94 + broad * 0.09 + (small - 0.5) * 0.07 + (grain - 0.5) * 0.055;
	vec3 soil = mud_color.rgb * (0.88 + 0.12 * smoothstep(0.05, 0.90, bank_position.y));
	ALBEDO = mix(soil, moss_color.rgb, moss) * mottling;
	ROUGHNESS = mix(0.94, 0.88, moss);
	SPECULAR = 0.22;
}
