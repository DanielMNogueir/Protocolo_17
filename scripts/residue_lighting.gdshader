shader_type canvas_item;
render_mode unshaded;
uniform float scene_time = 0.0;
uniform float restored = 0.0;
void fragment() {
    vec2 world = UV * vec2(2400.0, 1500.0);
    vec3 rgb = vec3(0.0);
    float a = 0.0;
    vec2 lamps[9] = vec2[9](
        vec2(300.0, 405.0), vec2(665.0, 700.0), vec2(700.0, 1210.0),
        vec2(1050.0, 401.0), vec2(1440.0, 695.0), vec2(1480.0, 1210.0),
        vec2(1800.0, 405.0), vec2(2140.0, 690.0), vec2(2230.0, 1180.0));
    for (int i = 0; i < 9; i++) {
        int zone = i / 3;
        float online = step(float(zone) + 0.5, restored);
        vec3 hue = mix(vec3(0.82, 0.40, 0.16), vec3(0.20, 0.86, 0.76), online);
        float distance = length((world - lamps[i]) / vec2(160.0, 103.0));
        float pulse = 0.89 + 0.11 * sin(scene_time * 2.4 + float(i) * 1.6);
        float light = exp(-distance * 2.0) * pulse * 0.19;
        rgb += hue * light;
        a += light;
    }
    vec2 toxic[2] = vec2[2](vec2(1079.0, 1230.0), vec2(1870.0, 1254.0));
    for (int i = 0; i < 2; i++) {
        float haze = exp(-length((world - toxic[i]) / vec2(140.0, 82.0)) * 2.0) * (0.10 + 0.025 * sin(scene_time * 1.9 + float(i)));
        rgb += vec3(0.78, 0.22, 0.45) * haze;
        a += haze;
    }
    COLOR = vec4(rgb / max(a, 0.001), min(a, 0.32));
}
