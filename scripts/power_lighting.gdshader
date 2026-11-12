shader_type canvas_item;
render_mode unshaded;
// Energy district blackout. Drawn over the world (under effects and HUD).
// Unpowered areas stay dark; Lia carries a short glow plus a flashlight cone
// along her aim; lamps, arcs, consoles and beams punch dynamic holes; every
// restored installation fades its compound (and the routes it powers) to light.

uniform vec2 map_size = vec2(1920.0, 1280.0);
uniform float scene_time = 0.0;
// 0..3, eased by the scene so each restoration fades in.
uniform float restored = 0.0;
uniform vec2 lia_pos = vec2(0.0);
uniform vec2 aim = vec2(1.0, 0.0);
uniform float flash = 0.0;
uniform float darkness = 0.76;
// x, y, radius, intensity (world space).
uniform vec4 lights[40];
uniform int light_count = 0;

const float S = 1.25;

float rect_light(vec2 p, vec4 r, float feather) {
	vec4 w = r * S;
	vec2 d = max(w.xy - p, p - (w.xy + w.zw));
	return 1.0 - smoothstep(0.0, feather, length(max(d, vec2(0.0))));
}

void fragment() {
	vec2 p = UV * map_size;
	float solar = clamp(restored, 0.0, 1.0);
	float tower = clamp(restored - 1.0, 0.0, 1.0);
	float bank = clamp(restored - 2.0, 0.0, 1.0);
	float zone = 0.0;
	zone = max(zone, solar * rect_light(p, vec4(50.0, 50.0, 560.0, 420.0), 70.0));
	zone = max(zone, solar * 0.8 * rect_light(p, vec4(30.0, 470.0, 1476.0, 120.0), 50.0));
	zone = max(zone, solar * 0.8 * rect_light(p, vec4(50.0, 590.0, 560.0, 390.0), 60.0));
	zone = max(zone, solar * 0.7 * rect_light(p, vec4(610.0, 190.0, 290.0, 100.0), 40.0));
	zone = max(zone, tower * rect_light(p, vec4(900.0, 50.0, 586.0, 420.0), 70.0));
	zone = max(zone, bank * rect_light(p, vec4(900.0, 590.0, 636.0, 390.0), 70.0));

	vec2 to_p = p - lia_pos;
	float dist = length(to_p);
	float glow = 1.0 - smoothstep(55.0, 150.0, dist);
	float facing = dot(to_p / max(dist, 0.001), normalize(aim));
	float cone = smoothstep(0.80, 0.93, facing) * (1.0 - smoothstep(170.0, 330.0, dist)) * 0.85;

	float points = 0.0;
	for (int i = 0; i < 40; i++) {
		if (i >= light_count) break;
		vec4 l = lights[i];
		float d = distance(p, l.xy);
		points += (1.0 - smoothstep(l.z * 0.25, l.z, d)) * l.w;
	}
	float light = clamp(zone + glow + cone + points, 0.0, 1.0);
	// A faint unsteady flicker sells the failing grid while it is dark.
	float flicker = (1.0 - zone) * 0.025 * sin(scene_time * 23.0 + p.x * 0.01) * sin(scene_time * 7.0);
	float alpha = mix(darkness + flicker, 0.05, light) * (1.0 - flash);
	vec3 night = mix(vec3(0.010, 0.028, 0.060), vec3(0.020, 0.060, 0.080), zone);
	COLOR = vec4(night, alpha);
}
