shader_type canvas_item;
render_mode unshaded;

uniform sampler2D field_texture : filter_linear, repeat_disable;
uniform sampler2D surface_noise : filter_linear, repeat_enable;
uniform vec2 world_size = vec2(2560.0, 1800.0);
uniform float water_time = 0.0;
uniform float recovery : hint_range(0.0, 1.0) = 0.0;
uniform float allow_pollution : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// Two-world-pixel cells stay fixed in the world when the camera moves.
	vec2 p = floor(UV * world_size / 2.0) * 2.0 + 1.0;
	vec3 field = texture(field_texture, p / world_size).rgb;
	float depth = field.r;
	vec2 flow = normalize(vec2(field.g, 1.0 - field.g));
	vec2 across = vec2(-flow.y, flow.x);
	vec2 moving = p - flow * water_time * 4.0;
	float broad = texture(surface_noise, moving / 640.0).r;
	vec2 ripple_uv = vec2(dot(moving, flow) / 800.0, dot(moving, across) / 220.0);
	float ripples = texture(surface_noise, ripple_uv).r;
	float grain = texture(surface_noise, moving / 360.0 + vec2(0.31, 0.67)).r;

	vec3 deep_color = mix(vec3(0.034, 0.115, 0.158), vec3(0.040, 0.145, 0.172), recovery);
	vec3 shallow_color = mix(vec3(0.105, 0.257, 0.263), vec3(0.137, 0.296, 0.282), recovery);
	float depth_mix = smoothstep(0.06, 0.85, depth);
	vec3 water = mix(shallow_color, deep_color, depth_mix);
	// Broad uneven tonal volumes replace the old rectangular patches.
	float tone = floor(broad * 7.0) / 7.0 - 0.5;
	water += vec3(0.017, 0.044, 0.044) * tone;
	water += vec3(0.004, 0.008, 0.007) * (floor(grain * 4.0) / 4.0 - 0.5);
	float phase = fract(ripples * 3.2 - water_time * 0.025);
	float ridge = smoothstep(0.74, 0.80, phase) * (1.0 - smoothstep(0.85, 0.91, phase));
	float broken = smoothstep(0.36, 0.59, grain);
	float reflection = smoothstep(0.51, 0.70, broad) * (1.0 - smoothstep(0.78, 0.92, broad));
	water += vec3(0.022, 0.046, 0.043) * reflection;
	water += vec3(0.065, 0.126, 0.112) * ridge * broken;
	float glint = ridge * smoothstep(0.72, 0.84, grain);
	water += vec3(0.080, 0.096, 0.076) * glint;
	// A narrow bank shadow sits in front of the shallow shelf, not a bright outline.
	float bank_shadow = 1.0 - smoothstep(0.0, 0.105, depth);
	water *= 1.0 - bank_shadow * 0.54;
	water *= 1.0 - field.b * 0.57;
	// Keep the polluted-west identity restrained and local to its original sector.
	float polluted = allow_pollution * (1.0 - recovery) * (1.0 - smoothstep(1110.0, 1340.0, p.x));
	water += vec3(0.016, -0.007, 0.008) * polluted * reflection;
	COLOR = vec4(water, 1.0);
}
