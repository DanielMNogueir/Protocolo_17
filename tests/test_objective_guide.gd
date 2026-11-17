extends SceneTree

const Guide = preload("res://scripts/objective_guide.gd")
const HUD = preload("res://scripts/field_hud.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var guide := Guide.new()
	var lia := Vector2(480, 270)
	var target := Vector2(840, 270)
	var safe := HUD.guide_safe_rect(Vector2(960, 540))
	guide.update(0, lia, lia + Vector2.UP * 40, target, Transform2D.IDENTITY, safe, true, "ESTAÇÃO")
	check(guide.mode == "arrow" and guide.arrow_direction() == Vector2.UP, "Arrow must follow the waypoint")
	check(guide.distance_meters() == 10, "Distance should be in meters")
	guide.update(8, lia, target, target, Transform2D.IDENTITY, safe, true, "ESTAÇÃO")
	check(guide.highlight == 1.0 and guide.ping, "Idle highlight should fire at 8 seconds")
	guide.update(8, lia, target, target, Transform2D.IDENTITY, safe, true, "ESTAÇÃO")
	check(guide.highlight == 0.0 and not guide.ping, "Do not highlight again for at least 12 seconds")
	guide.update(4, lia, target, target, Transform2D.IDENTITY, safe, true, "ESTAÇÃO")
	check(guide.highlight == 1.0, "Highlight can repeat after its cooldown")
	guide.update(0, lia + Vector2(45, 0), target, target, Transform2D.IDENTITY, safe, true, "ESTAÇÃO")
	check(guide.highlight == 0.0 and guide.idle == 0.0, "Progress should reset the highlight")
	guide.update(0, target - Vector2(60, 0), target, target, Transform2D.IDENTITY, safe, true, "ESTAÇÃO")
	check(guide.mode == "arrived", "Hide the arrow on arrival")
	guide.update(0, lia, target, target, Transform2D.IDENTITY, safe, false, "ESTAÇÃO")
	check(guide.mode == "hidden", "The guide should hide when blocked")

	for size in [Vector2(960, 540), Vector2(1440, 810)]:
		safe = HUD.guide_safe_rect(size)
		for i in 72:
			lia = size * 0.5
			target = lia + Vector2.from_angle(TAU * i / 72.0) * 1600
			guide.update(0, lia, target, target, Transform2D.IDENTITY, safe, true, "ESTAÇÃO")
			var marker := Rect2(guide.edge_position() - Vector2.ONE * Guide.EDGE_RADIUS, Vector2.ONE * Guide.EDGE_RADIUS * 2)
			check(guide.mode == "edge" and safe.encloses(marker), "Edge marker overlaps the HUD at angle %d" % i)
	var options := ConfigFile.new()
	options.set_value("interface", "guide", "NORMAL")
	options.set_value("interface", "guide_path", false)
	options.set_value("interface", "text_scale", 125)
	guide.configure(options)
	check(guide.intensity == Guide.NORMAL and not guide.path_enabled, "Saved guide options load consistently")
	check(HUD.font_size(12) == 15, "Large HUD text is 125 percent")
	guide.configure(ConfigFile.new())
	check(guide.intensity == Guide.STRONG and guide.path_enabled and HUD.font_size(12) == 12, "Fresh settings use the strong guide and standard text")
	print("OBJECTIVE_GUIDE_OK" if failures == 0 else "OBJECTIVE_GUIDE_FAILED")
	quit(0 if failures == 0 else 1)
