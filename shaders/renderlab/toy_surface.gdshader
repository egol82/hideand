shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
// A shadow-aware soft-toy surface. No vertex displacement, outlines or see-through emission.
uniform vec4 tint : source_color = vec4(0.8, 0.7, 0.6, 1.0);
uniform float roughness : hint_range(0.1, 1.0) = 0.7;
uniform int family = 0; // foam, vinyl, painted wood, fabric, plaster, glazed ceramic
uniform bool view_only = false;
uniform float sculpt = 0.55;
uniform bool baked_vertex_ao = false;
varying vec3 object_p;
varying vec3 object_n;
void vertex() { object_p = VERTEX; object_n = NORMAL; }
float pattern(vec3 p) {
    if (family == 1 || family == 5) return 0.0;
    float fade = 1.0 - smoothstep(0.004, 0.035, length(fwidth(p)));
    float micro = sin(p.x*117.0 + p.y*31.0) * sin(p.z*103.0-p.y*73.0);
    float weave = sin(p.x*138.0)*sin(p.y*138.0);
    float grain = sin(p.y*32.0 + sin(p.x*1.7)*0.7 + sin(p.z*2.2)*0.3);
    if (family == 3) return weave*fade*0.034;
    if (family == 2) return grain*0.014;
    return micro*fade*0.003;
}
void fragment() {
    float detail = pattern(object_p);
    float up = clamp(normalize(object_n).y*0.5+0.5,0.0,1.0);
    // Very restrained hand-painted value gradient; lighting and wall shadows still govern visibility.
    ALBEDO = tint.rgb * (1.0+detail) * mix(0.955,1.025,up);
    ROUGHNESS = clamp(roughness+detail*0.7,0.14,1.0);
    SPECULAR = family==1 || family==5 ? 0.42 : 0.22;
    METALLIC = 0.0;
    AO = baked_vertex_ao ? COLOR.r : 1.0;
    AO_LIGHT_AFFECT = 0.25;
}
void light() {
    float facing = max(dot(NORMAL,LIGHT),0.0);
    float soft = mix(facing,smoothstep(-0.12,1.0,dot(NORMAL,LIGHT)),sculpt*0.35);
    float att = view_only ? 1.0 : ATTENUATION;
    DIFFUSE_LIGHT += LIGHT_COLOR*att*soft/3.14159265;
    vec3 h = normalize(LIGHT+VIEW);
    float power = mix(72.0,8.0,roughness);
    float highlight = pow(max(dot(NORMAL,h),0.0),power)*(power+2.0)/(8.0*3.14159265);
    float sheen = pow(1.0-max(dot(NORMAL,VIEW),0.0),4.0)*0.015*sculpt;
    float spec = family==1 || family==5 ? 0.052 : 0.018;
    SPECULAR_LIGHT += LIGHT_COLOR*att*facing*(highlight*spec+sheen);
}
