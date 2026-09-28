shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 ivory : source_color = vec4(0.87,0.81,0.68,1.0);
uniform vec4 cream : source_color = vec4(0.95,0.89,0.77,1.0);
uniform vec4 grout : source_color = vec4(0.71,0.65,0.54,1.0);
varying vec3 p;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
    vec2 cell=p.xz/1.65;
    vec2 grid=abs(fract(cell)-0.5);
    vec2 fw=max(fwidth(cell),vec2(0.0004));
    float seam=max(smoothstep(0.487-fw.x,0.497+fw.x,grid.x),smoothstep(0.487-fw.y,0.497+fw.y,grid.y));
    float alternate=mod(floor(cell.x)+floor(cell.y),2.0);
    vec3 surface=mix(ivory.rgb,cream.rgb,alternate);
    float edge=smoothstep(0.455,0.49,max(grid.x,grid.y));
    ALBEDO=mix(surface*(1.0-edge*0.035),grout.rgb,seam*0.65);
    ROUGHNESS=0.68+0.12*seam;
    SPECULAR=0.27;
}
