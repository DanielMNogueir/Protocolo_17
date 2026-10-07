shader_type canvas_item;
render_mode unshaded;
uniform float lab_time = 0.0;
uniform float alarm = 0.0;
void fragment() {
	vec2 p = floor(UV * 192.0) / 192.0;
	vec3 cyan = vec3(0.25, 0.90, 0.79);
	vec3 red = vec3(0.96, 0.24, 0.40);
	vec3 tint = mix(cyan, red, alarm);
	float scan = pow(max(0.0, sin(p.y * 45.0 - lab_time * 1.6)), 18.0);
	float grid = step(0.94, fract(p.x * 12.0)) + step(0.96, fract(p.y * 10.0));
	float sweep = pow(max(0.0, 1.0 - abs(p.y - fract(lab_time * 0.12)) * 14.0), 2.0);
	float border = 1.0 - smoothstep(0.0, 0.035, min(min(p.x, 1.0-p.x), min(p.y, 1.0-p.y)));
	float signal = 1.0 - smoothstep(0.006, 0.020, abs(p.y - (0.52 + sin(p.x*19.0 + lab_time*2.0)*0.06)));
	COLOR = vec4(tint * (0.50 + scan*0.30 + sweep*0.40), 0.08 + grid*0.035 + scan*0.04 + sweep*0.13 + border*0.42 + signal*0.20);
}
