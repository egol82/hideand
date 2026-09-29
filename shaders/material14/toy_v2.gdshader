shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
// Phase 14: opaque material response only. No vertex displacement, alpha, emission or screen reads.
uniform vec4 tint : source_color = vec4(0.8, 0.7, 0.6, 1.0);
uniform sampler2D micro_tile : filter_linear_mipmap_anisotropic, repeat_enable;
uniform int family = 0; // foam, vinyl, painted wood, fabric, plaster, ceramic
uniform bool view_only = false;
uniform bool character_body = false;
uniform bool foam_cutout = false;
uniform float roughness : hint_range(0.2, 1.0) = 0.82;
uniform float detail_scale : hint_range(0.1, 12.0) = 3.0;
uniform float relief : hint_range(0.0, 0.002) = 0.00035;
uniform float detail_amount : hint_range(0.0, 1.0) = 1.0;
uniform float specular_strength : hint_range(0.0, 1.0) = 0.12;
uniform float coat_strength : hint_range(0.0, 0.2) = 0.0;
uniform float sheen_strength : hint_range(0.0, 0.2) = 0.02;
varying vec3 material_p;
varying vec3 material_n;
void vertex() {
    material_p = VERTEX;
    material_n = NORMAL;
}
vec3 tile_sample(vec3 p, vec3 n) {
    vec3 w = pow(abs(n),vec3(4.0));
    w /= max(dot(w,vec3(1.0)),0.0001);
    return texture(micro_tile,p.yz).rgb*w.x + texture(micro_tile,p.zx).rgb*w.y + texture(micro_tile,p.xy).rgb*w.z;
}
void fragment() {
    vec3 n = normalize(NORMAL);
    vec3 on = normalize(material_n);
    vec3 p = material_p*detail_scale;
    vec3 micro = tile_sample(p,on);
    float pixel_span = max(length(dFdx(p)),length(dFdy(p)));
    float fade = 1.0-smoothstep(0.012,0.09,pixel_span);
    float amount = detail_amount*fade;
    // Surface-gradient bump: does not require tangent data, so tubes and skinned body stay intact.
    // Differentiate raw height, not the derivative-based fade (no nested derivatives).
    vec3 dx = dFdx(VERTEX); vec3 dy = dFdy(VERTEX);
    vec3 rx = cross(dy,n); vec3 ry = cross(n,dx);
    float det = dot(dx,rx);
    vec3 gradient = (rx*dFdx(micro.r)+ry*dFdy(micro.r))*sign(det)/max(abs(det),0.000001);
    vec3 bent = n-gradient*relief*amount;
    NORMAL = normalize(mix(n,normalize(bent),0.65));
    vec3 base = tint.rgb;
    float variation = (micro.g-0.5)*amount;
    float local_roughness = roughness;
    if (family==0) {
        // A matte cut face and a slightly denser rounded edge; only the existing fill gets this mask.
        float edge = foam_cutout ? 1.0-smoothstep(0.40,0.91,abs(on.y)) : 0.0;
        base *= 1.0+variation*0.052-edge*0.035;
        local_roughness += (micro.b-0.5)*0.065*amount-edge*0.075;
    } else if (family==1) {
        // Broad molded-vinyl coating. Face/belly tint uses the body's existing rest UVs.
        base *= 0.98+0.035*smoothstep(0.10,0.90,UV.y);
        if (character_body) {
            float front = smoothstep(0.10,0.72,on.z);
            float face = exp(-pow((UV.y-0.61)*6.5,2.0))*front;
            float belly = exp(-pow((UV.x-0.5)*5.0,2.0)-pow((UV.y-0.39)*6.0,2.0))*front;
            base = mix(base,base*vec3(1.028,0.983,0.984),face*0.65);
            base = mix(base,min(base*1.10,vec3(1.0)),belly*0.38);
        }
        local_roughness += variation*0.014;
    } else if (family==2) {
        // Paint over wood, not photographic bare timber. Grain follows each object's coordinates.
        float grain = sin(material_p.y*29.0+sin(material_p.x*2.0)*0.65+material_p.z*0.6);
        base *= 1.0+grain*0.012+variation*0.026;
        local_roughness += variation*0.045;
    } else if (family==3) {
        base *= 1.0+variation*0.130;
        local_roughness += variation*0.045;
    } else if (family==4) {
        base *= 1.0+variation*0.033;
    } else {
        local_roughness += variation*0.008;
    }
    ALBEDO = clamp(base,vec3(0.0),vec3(1.0));
    ROUGHNESS = clamp(local_roughness,0.24,0.98);
    SPECULAR = specular_strength;
    METALLIC = 0.0;
}
float ggx(float nh, float nv, float nl, float a) {
    float a2=a*a;
    float d=a2/(3.14159265*pow(nh*nh*(a2-1.0)+1.0,2.0));
    float k=(a+1.0)*(a+1.0)*0.125;
    float g1=nv/(nv*(1.0-k)+k);
    float g2=nl/(nl*(1.0-k)+k);
    return d*g1*g2/max(4.0*nv*nl,0.001);
}
void light() {
    vec3 n=normalize(NORMAL); vec3 v=normalize(VIEW);
    float nl=max(dot(n,LIGHT),0.0); float nv=max(dot(n,v),0.001);
    vec3 hv=LIGHT+v; vec3 h=hv/max(length(hv),0.001);
    float nh=max(dot(n,h),0.0); float vh=max(dot(v,h),0.0);
    // View models keep the existing directional shadow exception; local light falloff remains.
    float att=(view_only && LIGHT_IS_DIRECTIONAL) ? 1.0 : ATTENUATION;
    float f0=0.02+specular_strength*0.055;
    float fresnel=f0+(1.0-f0)*pow(1.0-vh,5.0);
    float diffuse=nl;
    if (family==1) {
        // Small lit-side wrap is an artistic diffusion approximation, NOT screen-space SSS or GI.
        float wrap=clamp((dot(n,LIGHT)+0.12)/1.12,0.0,1.0);
        diffuse=mix(nl,wrap,0.18);
    }
    DIFFUSE_LIGHT += LIGHT_COLOR*att*diffuse*(1.0-f0)/3.14159265;
    float spec=ggx(nh,nv,max(nl,0.001),max(0.17,ROUGHNESS*ROUGHNESS))*fresnel;
    float coat=ggx(nh,nv,max(nl,0.001),0.24)*0.04*coat_strength;
    float fiber=sheen_strength*pow(1.0-nv,3.0)*sqrt(max(0.0,1.0-nh*nh));
    SPECULAR_LIGHT += LIGHT_COLOR*att*nl*(min(spec,4.0)+min(coat,0.5)+fiber);
}
