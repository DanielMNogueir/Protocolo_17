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
		world_to_screen: Transform2D, safe: Rect2, active: bool, place_name: String) -> void:
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
	var viewport := Rect2(Vector2.ZERO, Vector2(safe.end.x + safe.position.x, safe.end.y + HUD.GUIDE_BOTTOM))
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


static func draw_arrow(canvas: CanvasItem, at: Vector2, direction: Vector2, color: Color, scale: float = 1.0) -> void:
	for offset in [0.0, -10.0]:
		var tip: Vector2 = at + direction * offset * scale
		var left := tip + direction.rotated(2.52) * 16.0 * scale
		var right := tip + direction.rotated(-2.52) * 16.0 * scale
		var chevron := PackedVector2Array([left, tip, right])
		canvas.draw_polyline(chevron, Color(HUD.INK, color.a), 8.0 * scale, true)
		canvas.draw_polyline(chevron, color, 4.0 * scale, true)


func draw_world(canvas: CanvasItem, time: float, intensity: int) -> void:
	if mode == "hidden":
		return
	var alpha := 0.65 if in_combat else 0.95
	var direction := arrow_direction()
	if mode != "arrived" and not direction.is_zero_approx():
		var tip := _lia + direction * (ARROW_OFFSET + 5.0 * sin(time * TAU * 1.2)) + Vector2(0, 18)
		draw_arrow(canvas, tip, direction, Color(HUD.GOLD, alpha))
	if intensity == MINIMAL:
		return
	if intensity == STRONG:
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


func draw_screen(canvas: CanvasItem, time: float, intensity: int) -> void:
	if intensity == MINIMAL or mode == "hidden" or mode == "arrived":
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
	return clampf(ThemeDB.fallback_font.get_string_size(place, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 24.0,
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
