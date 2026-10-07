shader_type canvas_item;
render_mode unshaded;
uniform float lab_time = 0.0;
uniform float alarm = 0.0;
void fragment() {
	vec2 p = floor(UV * 192.0) / 192.0;
	float a = sin(p.x*38.0 + p.y*19.0 - lab_time*1.7);
	float b = sin(p.x*17.0 - p.y*31.0 + lab_time*1.1);
	float caustic = pow(max(0.0, (a+b)*0.5), 5.0);
	float ripple = pow(max(0.0, sin(length((p-vec2(0.25,0.5))*vec2(1.0,0.6))*70.0-lab_time*3.0)), 14.0);
	vec3 dark = vec3(0.035,0.19,0.22);
	vec3 light = vec3(0.23,0.68,0.56);
	vec3 water = mix(dark, light, 0.18 + caustic*0.65 + ripple*0.12);
	water += vec3(0.13,0.015,0.025) * alarm * (0.4 + 0.2*sin(lab_time*2.0));
	COLOR = vec4(water, 1.0);
}
