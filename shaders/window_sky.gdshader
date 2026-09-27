shader_type spatial;
render_mode unshaded;
void fragment() {
	vec3 sky = mix(vec3(0.77,0.90,0.89),vec3(0.42,0.67,0.76),UV.y);
	float cloud = 1.0-smoothstep(0.10,0.18,length((UV-vec2(0.3,0.65))*vec2(0.7,2.0)));
	cloud = max(cloud,1.0-smoothstep(0.1,0.16,length((UV-vec2(0.75,0.27))*vec2(0.8,2.0))));
	ALBEDO = mix(sky,vec3(0.90,0.95,0.91),cloud*0.85);
}
