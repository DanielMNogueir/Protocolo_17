shader_type canvas_item;
render_mode unshaded;
uniform float lab_time = 0.0;
uniform float alarm = 0.0;

void fragment() {
 vec4 texel = texture(TEXTURE, UV);
 vec3 c = texel.rgb;
 vec2 p = UV * vec2(1536.0, 1024.0);
 float cyan = smoothstep(0.07, 0.25, min(c.g, c.b) - c.r);
 float core = step(792.0,p.x)*step(p.x,1030.0)*step(262.0,p.y)*step(p.y,465.0);
 float left_glass = step(56.0,p.x)*step(p.x,201.0)*step(359.0,p.y)*step(p.y,550.0);
 float right_glass = step(1316.0,p.x)*step(p.x,1454.0)*step(397.0,p.y)*step(p.y,600.0);
 float glass = max(core,max(left_glass,right_glass));
 float scan = pow(max(0.0,sin(p.y*0.045-lab_time*2.0)),12.0);
 float shimmer = sin(p.y*0.085 + sin(p.x*0.04+lab_time)*1.4-lab_time*3.0);
 c += cyan*(0.015+scan*0.06) + glass*cyan*shimmer*0.027;
 // Faint moving reflections travel across the plant chambers' green glass too.
 c += glass*(vec3(0.006,0.018,0.024)*scan+vec3(0.008,0.018,0.014)*shimmer*0.45);
 float pulse = 0.85+0.15*sin(lab_time*3.0);
 vec3 red_emission = vec3(max(c.r,c.b)*1.25,c.g*0.18,c.b*0.13);
 c = mix(c,red_emission,alarm*cyan*0.96*pulse);
 float light = exp(-length((p-vec2(920.0,590.0))/vec2(310.0,200.0)));
 float material = smoothstep(0.1,0.3,max(c.r,max(c.g,c.b)));
 c = mix(c,c*vec3(1.22,0.82,0.85),alarm*light*material*pulse*0.65);
 COLOR = vec4(clamp(c,0.0,1.0),texel.a);
}
