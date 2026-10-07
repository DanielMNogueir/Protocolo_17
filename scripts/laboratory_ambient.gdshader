shader_type canvas_item;
render_mode unshaded;
uniform sampler2D shadow_field : filter_linear, repeat_disable;
uniform float lab_time = 0.0;
uniform float alarm = 0.0;
uniform float atmosphere = 0.0;
void fragment() {
	vec2 p = UV;
	vec2 texel = vec2(1.0/192.0,1.0/128.0);
	vec2 field = texture(shadow_field,p).rg*0.40;
	field += texture(shadow_field,p+vec2(texel.x,0.0)).rg*0.15;
	field += texture(shadow_field,p-vec2(texel.x,0.0)).rg*0.15;
	field += texture(shadow_field,p+vec2(0.0,texel.y)).rg*0.15;
	field += texture(shadow_field,p-vec2(0.0,texel.y)).rg*0.15;
	float edge = 1.0 - smoothstep(0.0,0.16,min(min(p.x,1.0-p.x),min(p.y,1.0-p.y)));
	float central = exp(-length((p-vec2(0.45,0.38))*vec2(1.15,0.9))*2.5);
	float pulse = 0.80 + 0.20*sin(lab_time*2.4);
	float red_pool = exp(-length((p-vec2(0.66,0.37))*vec2(1.2,0.8))*5.0)*alarm*pulse;
	vec3 shade = mix(vec3(0.015,0.025,0.055),vec3(0.33,0.025,0.050),red_pool*0.75);
	float shadow = field.r*0.52 + field.g*0.20;
	float ambient = 0.09 + edge*0.23 - central*0.055 + red_pool*0.16;
	COLOR = vec4(shade,mix(shadow,ambient,atmosphere));
}
