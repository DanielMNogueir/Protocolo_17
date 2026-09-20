class_name P17LiaOfficial
extends RefCounted
## Pure presentation: never reads input or modifies a simulation object.
const WALK := preload("res://assets/lia_official/walk.png")
const ACTIONS := preload("res://assets/lia_official/actions.png")
const layout: Dictionary = preload("res://assets/lia_official/frames.gd").DATA
const ARMED_WALK := preload("res://assets/lia_expanded/walk.png")
const ARMED_IDLE := preload("res://assets/lia_expanded/idle.png")
const expanded: Dictionary = preload("res://assets/lia_expanded/frames.gd").DATA
const WALK_FPS := 18.0 # Eight frames retain the previous 4/9-second stride.
const FOOT_Y := 18.0

static func direction_index(aim: Vector2) -> int:
	if aim.length_squared() < 0.001:
		return 0
	if absf(aim.x) > absf(aim.y):
		return 2 if aim.x > 0 else 1
	return 3 if aim.y < 0 else 0

static func frame_for(aim: Vector2, time: float, moving: bool, action: String = "idle") -> Dictionary:
	var direction := direction_index(aim) # down, left, right, up
	var row := 0
	var col: int = [0, 2, 1, 3][direction]
	var sheet := "actions"
	if moving:
		sheet = "walk"
		row = direction
		col = posmod(int(floor(time * 9.0)), 4)
	elif action == "fire":
		row = 1
		col = direction
	elif action == "repair":
		row = 3
	var values: Array = layout[sheet][row][col]
	var region := Rect2(values[0], values[1], values[2], values[3])
	var dimensions := region.size * float(layout.scale)
	return {"texture": WALK if sheet == "walk" else ACTIONS, "region": region,
		"rect": Rect2(Vector2(-dimensions.x * 0.5, 18 - dimensions.y), dimensions),
		"sheet": sheet, "row": row, "column": col}

static func draw(canvas: Node2D, pos: Vector2, aim: Vector2, time: float, moving: bool, hurt: bool, dashing: bool, action: String) -> void:
	var frame := frame_for(aim, time, moving or dashing, action)
	var rect: Rect2 = frame.rect
	rect.position += pos.round()
	canvas.draw_rect(Rect2(pos.round() + Vector2(-12, 12), Vector2(24, 6)), Color(0.035, 0.07, 0.08, 0.35))
	canvas.draw_rect(Rect2(pos.round() + Vector2(-8, 10), Vector2(16, 10)), Color(0.035, 0.07, 0.08, 0.27))
	if dashing:
		for echo in range(3, 0, -1):
			var trail := rect
			trail.position -= aim.normalized() * echo * 8.0
			canvas.draw_texture_rect_region(frame.texture, trail, frame.region, Color(0.34, 0.76, 0.68, 0.09 * (4 - echo)))
	canvas.draw_texture_rect_region(frame.texture, rect, frame.region, Color(1.6, 1.2, 1.2, 0.72) if hurt else Color.WHITE)

static func idle_frame(time: float) -> int:
	# A brief blink, separate from the slower breathing loop.
	if fposmod(time, 4.0) >= 3.84:
		return 3
	return [0, 1, 2, 1][posmod(int(floor(time / .55)), 4)]

static func held_pose(aim: Vector2, time: float, moving: bool) -> Dictionary:
	var direction := direction_index(aim)
	var sheet := "walk" if moving else "idle"
	var index := posmod(int(floor(time * WALK_FPS)), 8) if moving else idle_frame(time)
	var frame: Dictionary = expanded[sheet][direction][index]
	var values: Array = frame.region
	var region := Rect2(values[0], values[1], values[2], values[3])
	var anchor := Vector2(frame.anchor[0], frame.anchor[1])
	var scale_value: float = expanded.scales[sheet]
	var rect := Rect2((region.position - anchor) * scale_value + Vector2(0, FOOT_Y), region.size * scale_value)
	var muzzle := (Vector2(frame.muzzle[0], frame.muzzle[1]) - anchor) * scale_value + Vector2(0, FOOT_Y)
	# Each frame contains the entire character, both gripping hands and the gun.
	return {"parts": [{"texture": ARMED_WALK if moving else ARMED_IDLE, "region": region, "rect": rect, "upper": false}],
		"muzzle": muzzle, "direction": direction, "frame": index, "sheet": sheet, "scale": scale_value}

static func recoil_point(point: Vector2, aim: Vector2, recoil: float) -> Vector2:
	# An affine lean about the ground line, keeping feet planted and grip intact.
	# The muzzle uses this same transform; gameplay coordinates are never changed.
	return point - aim.normalized() * recoil * ((FOOT_Y - point.y) / 48.0)

static func draw_held(canvas: Node2D, pos: Vector2, aim: Vector2, time: float, moving: bool, hurt: bool, dashing: bool, recoil: float) -> Vector2:
	var pose := held_pose(aim, time, moving or dashing)
	var origin := pos.round()
	var part: Dictionary = pose.parts[0]
	canvas.draw_rect(Rect2(origin + Vector2(-12, 12), Vector2(24, 6)), Color(0.035, 0.07, 0.08, .35))
	if dashing:
		for echo in range(3, 0, -1):
			var trail: Rect2 = part.rect
			trail.position += origin - aim.normalized() * echo * 8.0
			canvas.draw_texture_rect_region(part.texture, trail, part.region, Color(.34, .76, .68, .09 * (4 - echo)))
	var rect: Rect2 = part.rect
	var tint := Color(1.6, 1.2, 1.2, .72) if hurt else Color.WHITE
	if recoil > 0:
		var corners := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
		for i in corners.size(): corners[i] = origin + recoil_point(corners[i], aim, recoil)
		var texture: Texture2D = part.texture
		var region: Rect2 = part.region
		var uv := Rect2(region.position / texture.get_size(), region.size / texture.get_size())
		canvas.draw_polygon(corners, PackedColorArray([tint]), PackedVector2Array([uv.position, Vector2(uv.end.x, uv.position.y), uv.end, Vector2(uv.position.x, uv.end.y)]), texture)
	else:
		rect.position += origin
		canvas.draw_texture_rect_region(part.texture, rect, part.region, tint)
	return origin + recoil_point(pose.muzzle, aim, recoil)
