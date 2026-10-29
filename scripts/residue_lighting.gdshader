shader_type canvas_item;
render_mode unshaded;
uniform float scene_time = 0.0;
uniform float restored = 0.0;
uniform float ventilation = 0.0;

void fragment() {
    // Use the same source coordinates as the plate and its physical geometry.
    vec2 p = UV * vec2(1536.0, 1024.0);
    vec3 rgb = vec3(0.0);
    float alpha = 0.0;
    vec2 lamps[10] = vec2[10](
        vec2(181.0, 444.0), vec2(398.0, 444.0), vec2(730.0, 446.0),
        vec2(1008.0, 447.0), vec2(1267.0, 448.0), vec2(1505.0, 448.0),
        vec2(265.0, 525.0), vec2(675.0, 527.0), vec2(1253.0, 528.0), vec2(1195.0, 916.0));
    for (int i = 0; i < 10; i++) {
        float light = exp(-length((p - lamps[i]) / vec2(55.0, 36.0)) * 2.1) * 0.13;
        rgb += vec3(1.0, 0.69, 0.30) * light;
        alpha += light;
    }
    vec2 controls[3] = vec2[3](vec2(224.0, 294.0), vec2(1325.0, 305.0), vec2(1100.0, 891.0));
    for (int i = 0; i < 3; i++) {
        float online = step(float(i) + 0.5, restored);
        float glow = exp(-length((p - controls[i]) / vec2(36.0, 25.0)) * 2.0) * (0.08 + 0.025 * sin(scene_time * 2.5));
        rgb += mix(vec3(0.93, 0.59, 0.22), vec3(0.29, 0.93, 0.81), online) * glow;
        alpha += glow;
    }
    float furnace = exp(-length((p - vec2(1409.0, 211.0)) / vec2(54.0, 40.0)) * 2.0) * (0.09 + 0.018 * sin(scene_time * 9.0) + 0.012 * sin(scene_time * 17.0));
    rgb += vec3(1.0, 0.37, 0.08) * furnace;
    alpha += furnace;
    vec2 vents[2] = vec2[2](vec2(1321.0, 37.0), vec2(1247.0, 839.0));
    for (int i = 0; i < 2; i++) {
        float rise = mod(scene_time * 8.0 + float(i) * 18.0, 49.0);
        vec2 smoke_pos = vents[i] + vec2(sin(scene_time * 0.7 + float(i)) * 6.0, -rise);
        float smoke = exp(-length((p - smoke_pos) / vec2(15.0 + rise * 0.2, 10.0)) * 2.0) * (1.0 - rise / 49.0) * 0.055;
        if (i == 1) { smoke *= 1.0 - clamp(ventilation * 0.5, 0.0, 1.0); }
        rgb += vec3(0.65, 0.69, 0.61) * smoke;
        alpha += smoke;
    }
    COLOR = vec4(rgb / max(alpha, 0.001), min(alpha, 0.23));
}
