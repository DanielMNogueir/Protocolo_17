shader_type canvas_item;
render_mode unshaded;
uniform sampler2D reference_plate : source_color, filter_linear, repeat_disable;
uniform vec2 quadrant = vec2(0.0);

// The painted plate is resampled separately from the nearest-filtered sprites.
// A bounded detail pass restores local contrast without bright edge halos.
void fragment() {
    vec4 base = texture(TEXTURE, UV);
    vec3 left = texture(TEXTURE, UV - vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).rgb;
    vec3 right = texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).rgb;
    vec3 up = texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y)).rgb;
    vec3 down = texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y)).rgb;
    vec3 low = min(base.rgb, min(min(left, right), min(up, down)));
    vec3 high = max(base.rgb, max(max(left, right), max(up, down)));
    vec3 detail = base.rgb - (left + right + up + down) * 0.25;
    vec3 crisp = clamp(base.rgb + detail * 0.12, low, high);
    // A narrow join uses the composition plate to avoid seams between tiles.
    vec2 edge = min(UV, vec2(1.0) - UV);
    float blend = smoothstep(0.0, 0.018, min(edge.x, edge.y));
    vec3 reference = texture(reference_plate, (quadrant + UV) * 0.5).rgb;
    COLOR = vec4(mix(reference, crisp, blend), base.a);
}
