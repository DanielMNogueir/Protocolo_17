class_name P17ObjectiveGuide
extends RefCounted

const HUD = preload("res://scripts/field_hud.gd")
const NEAR := 70.0
const ARROW_OFFSET := 56.0
const PX_PER_METER := 36.0
const IDLE_TIME := 8.0
const PROGRESS_STEP := 40.0
const EDGE_RADIUS := 22.0
const MINIMAL := 0
const NORMAL := 1
const STRONG := 2
const INTENSITY_NAMES := ["MÍNIMA", "NORMAL", "FORTE"]
const SETTINGS_PATH := "user://settings.cfg"

var intensity := STRONG
var path_enabled := true
var route := PackedVector2Array()
var tip_remaining := 0.0
var _district := ""
var _tip_started := true
var _tip_origin := Vector2.ZERO

var mode := "hidden"
var place := ""
var idle := 0.0
var highlight := 0.0
var in_combat := false
var ping := false
var _lia := Vector2.ZERO
var _next := Vector2.ZERO
var _target := Vector2.ZERO
var _transform := Transform2D.IDENTITY
var _safe := Rect2()
var _distance := 0.0
var _progress_distance := 0.0
var _since_highlight := 12.0
var _has_goal := false


func update(delta: float, lia: Vector2, next_point: Vector2, target: Vector2,
		world_to_screen: Transform2D, safe: Rect2, active: bool, place_name: String,
		screen_size: Vector2 = Vector2.ZERO) -> void:
	ping = false
	if not active:
		mode = "hidden"
		return
	var changed := not _has_goal or place != place_name
	_has_goal = true
	_lia = lia
	_next = next_point
	_target = target
	_transform = world_to_screen
	_safe = safe
	place = place_name
	_distance = lia.distance_to(target)
	var extent := screen_size
	if extent == Vector2.ZERO:
		extent = Vector2(safe.end.x + safe.position.x, safe.end.y + HUD.GUIDE_BOTTOM)
	var viewport := Rect2(Vector2.ZERO, extent)
	var target_on_screen := viewport.has_point(world_to_screen * target)
	mode = "arrived" if _distance < NEAR else ("arrow" if target_on_screen else "edge")

	_since_highlight += delta
	highlight = maxf(0.0, highlight - delta / 1.5)
	if changed or _progress_distance - _distance >= PROGRESS_STEP or mode == "arrived":
		idle = 0.0
		highlight = 0.0
		_progress_distance = _distance
		ping = changed
	elif not in_combat:
		idle += delta
		if idle >= IDLE_TIME and _since_highlight >= 12.0:
			idle = 0.0
			highlight = 1.0
			_since_highlight = 0.0
			ping = true


func arrow_direction() -> Vector2:
	var direction := _lia.direction_to(_next)
	return direction if direction != Vector2.ZERO else _lia.direction_to(_target)


func distance_meters() -> int:
	return roundi(_distance / PX_PER_METER)


func edge_position() -> Vector2:
	var box := _safe.grow(-26.0)
	var origin := _transform * _lia
	var start := origin.clamp(box.position, box.end)
	var direction := origin.direction_to(_transform * _target)
	if direction.is_zero_approx():
		return start
	var tx := INF
	var ty := INF
	if absf(direction.x) > 0.0001:
		tx = ((box.end.x if direction.x > 0.0 else box.position.x) - start.x) / direction.x
	if absf(direction.y) > 0.0001:
		ty = ((box.end.y if direction.y > 0.0 else box.position.y) - start.y) / direction.y
	return start + direction * minf(tx, ty)


func draw_world(canvas: CanvasItem, time: float, strength: int) -> void:
	if mode == "hidden":
		return
	var alpha := 0.65 if in_combat else 0.95
	var direction := arrow_direction()
	if mode != "arrived" and not direction.is_zero_approx():
		var tip := _lia + direction * (ARROW_OFFSET + 5.0 * sin(time * TAU * 1.2)) + Vector2(0, 18)
		HUD.chevron(canvas, tip, direction, Color(HUD.GOLD, alpha))
	if strength == MINIMAL:
		return
	if strength == STRONG:
		if path_enabled and mode != "arrived": _draw_path(canvas, alpha)
		var vertices := PackedVector2Array([_target + Vector2(-8, 0), _target + Vector2(8, 0),
			_target + Vector2(8, -140), _target + Vector2(-8, -140)])
		canvas.draw_polygon(vertices, PackedColorArray([Color(HUD.GOLD, 0.35), Color(HUD.GOLD, 0.35),
			Color(HUD.GOLD, 0.0), Color(HUD.GOLD, 0.0)]))
		if highlight > 0.0 and not in_combat:
			var angle := direction.angle()
			canvas.draw_arc(_lia, lerpf(40.0, 140.0, 1.0 - highlight), angle - 0.35, angle + 0.35,
				16, Color(HUD.GOLD, highlight * 0.8), 3, true)
	var ring := PackedVector2Array()
	for i in 33:
		var angle := TAU * i / 32.0
		ring.append(_target + Vector2(cos(angle) * 17.0, sin(angle) * 8.5))
	canvas.draw_polyline(ring, Color(HUD.GOLD, 0.8 + 0.2 * sin(time * TAU)), 2, true)
	var diamond := _target + Vector2(0, -80 + 4 * sin(time * TAU))
	_draw_diamond(canvas, diamond)


func _draw_path(canvas: CanvasItem, alpha: float) -> void:
	if route.is_empty():
		return
	var nearest := 0
	var distance := INF
	for i in route.size():
		var current := _lia.distance_squared_to(route[i])
		if current < distance:
			distance = current
			nearest = i
	if nearest + 1 < route.size() and (route[nearest + 1] - route[nearest]).dot(_lia - route[nearest]) >= 0.0:
		nearest += 1
	var previous := _lia
	var carried := 0.0
	var dots := 0
	for i in range(nearest, mini(nearest + 6, route.size())):
		var finish := route[i]
		var step := previous.distance_to(finish)
		var next_dot := 28.0 - carried
		while next_dot <= step and dots < 6:
			var point := previous.move_toward(finish, next_dot)
			canvas.draw_circle(point, 1.5, Color(HUD.GOLD, alpha * (0.6 - dots * 0.075)), true, -1.0, true)
			next_dot += 28.0
			dots += 1
		previous = finish
		carried = fposmod(carried + step, 28.0)
		if dots >= 6: break


func draw_screen(canvas: CanvasItem, time: float, strength: int) -> void:
	if strength == MINIMAL or mode == "hidden" or mode == "arrived":
		return
	if mode == "arrow":
		var anchor := _transform * (_target + Vector2(0, -111 + 4 * sin(time * TAU)))
		var rect := _label_rect(anchor, Vector2(_label_width(), 26))
		_draw_label(canvas, rect, false)
		return
	var at := edge_position()
	var direction := (_transform * _lia).direction_to(_transform * _target)
	canvas.draw_circle(at, EDGE_RADIUS, Color(HUD.INK, 0.94))
	canvas.draw_arc(at, EDGE_RADIUS, 0, TAU, 36, HUD.GOLD, 2, true)
	canvas.draw_colored_polygon(PackedVector2Array([at + direction * 11.0,
		at + direction.rotated(2.4) * 10.0, at + direction.rotated(-2.4) * 10.0]), HUD.GOLD)
	var width := _label_width()
	var on_left := at.x > _safe.get_center().x
	var offset := (EDGE_RADIUS + 5.0 + width * 0.5) * (-1.0 if on_left else 1.0)
	_draw_label(canvas, _label_rect(at + Vector2(offset, 0), Vector2(width, 42)), true)


func _label_width() -> float:
	return clampf(ThemeDB.fallback_font.get_string_size(place, HORIZONTAL_ALIGNMENT_LEFT, -1, HUD.font_size(11)).x + 24.0,
		80.0, minf(256.0, _safe.size.x))


func _label_rect(at: Vector2, size: Vector2) -> Rect2:
	return Rect2((at - size * 0.5).clamp(_safe.position, _safe.end - size), size)


func _draw_label(canvas: CanvasItem, rect: Rect2, distance: bool) -> void:
	HUD.plate(canvas, rect, Color(HUD.INK, 0.98), 5)
	HUD.edge(canvas, rect, HUD.GOLD, 1.0, 5)
	HUD.centered(canvas, HUD.fit(place, rect.size.x - 16.0, 11), rect.get_center() + Vector2(0, -3 if distance else 4), 11)
	if distance:
		HUD.centered(canvas, "%d m" % distance_meters(), rect.get_center() + Vector2(0, 12), 10, HUD.GOLD)


static func _draw_diamond(canvas: CanvasItem, at: Vector2) -> void:
	var shape := PackedVector2Array([at + Vector2(0, -9), at + Vector2(7, 0),
		at + Vector2(0, 9), at + Vector2(-7, 0), at + Vector2(0, -9)])
	canvas.draw_colored_polygon(shape.slice(0, 4), HUD.GOLD)
	canvas.draw_polyline(shape, HUD.INK, 2)


func configure(config: ConfigFile, district: String = "") -> void:
	var saved: Variant = config.get_value("interface", "guide", STRONG)
	var preferred: int = INTENSITY_NAMES.find(saved) if saved is String else int(saved)
	intensity = STRONG if preferred not in [MINIMAL, NORMAL, STRONG] else preferred
	path_enabled = bool(config.get_value("interface", "guide_path", true))
	HUD.text_scale_percent = 125 if config.get_value("interface", "text_scale", 100) == 125 else 100
	_district = district
	_tip_started = district.is_empty() or bool(config.get_value("tutorial", "arrow_" + district, false))


func cues(delta: float, audio: Node) -> void:
	if mode == "hidden":
		return
	if ping and intensity == STRONG:
		audio.play_sfx("guide_ping")
	if not _tip_started and intensity > MINIMAL and mode != "arrived":
		_tip_started = true
		var config := ConfigFile.new()
		config.load(SETTINGS_PATH)
		config.set_value("tutorial", "arrow_" + _district, true)
		config.save(SETTINGS_PATH)
		tip_remaining = 6.0
		_tip_origin = _lia
	tip_remaining = 0.0 if _lia.distance_to(_tip_origin) >= 120.0 else maxf(0.0, tip_remaining - delta)


func draw_tip(canvas: CanvasItem) -> void:
	if tip_remaining <= 0.0 or intensity == MINIMAL or mode == "hidden" or mode == "arrived":
		return
	var at := _transform * _lia + Vector2(0, 56)
	var rect := _label_rect(at, Vector2(178, 25))
	HUD.plate(canvas, rect, HUD.INK, 5)
	HUD.edge(canvas, rect, HUD.GOLD, 1.0, 5)
	HUD.centered(canvas, "SIGA A SETA DOURADA", rect.get_center() + Vector2(0, 4), 10, HUD.GOLD)
