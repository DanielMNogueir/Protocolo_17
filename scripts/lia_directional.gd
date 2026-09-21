extends RefCounted
## Full-body sprite poses at 15-degree intervals. Presentation only.
const DATA: Dictionary = preload("res://assets/lia_directional/frames.gd").DATA
const IDLE := [preload("res://assets/lia_directional/idle.png"), preload("res://assets/lia_directional/blink.png")]
const WALK := [
	preload("res://assets/lia_directional/walk0.png"), preload("res://assets/lia_directional/walk1.png"),
	preload("res://assets/lia_directional/walk2.png"), preload("res://assets/lia_directional/walk3.png"),
	preload("res://assets/lia_directional/walk4.png"), preload("res://assets/lia_directional/walk5.png"),
	preload("res://assets/lia_directional/walk6.png"), preload("res://assets/lia_directional/walk7.png")]
const DIRECTION_COUNT := 24
const STEP := TAU / DIRECTION_COUNT
const WALK_FPS := 18.0
const FOOT_Y := 18.0

static func direction_index(aim: Vector2) -> int:
	if aim.length_squared() < .001: return 6 # Front/down default.
	# Half-open sectors [centre - 7.5, centre + 7.5), wrapping at 360 degrees.
	return posmod(int(floor((aim.angle() + STEP * .5) / STEP)), DIRECTION_COUNT)

static func idle_frame(time: float) -> int:
	return 1 if fposmod(time, 4.0) >= 3.84 else 0

static func pose(aim: Vector2, time: float, moving: bool) -> Dictionary:
	var direction := direction_index(aim)
	var state := "walk" if moving else "idle"
	var index := posmod(int(floor(time * WALK_FPS)), 8) if moving else idle_frame(time)
	var frame: Dictionary = DATA[state][direction][index]
	var values: Array = frame.region
	var region := Rect2(values[0], values[1], values[2], values[3])
	var anchor := Vector2(frame.anchor[0], frame.anchor[1])
	var scale_value: float = DATA.scales[frame.sheet]
	var rect := Rect2((region.position - anchor) * scale_value + Vector2(0, FOOT_Y), region.size * scale_value)
	var muzzle := (Vector2(frame.muzzle[0], frame.muzzle[1]) - anchor) * scale_value + Vector2(0, FOOT_Y)
	if not moving:
		# Gentle breathing about the floor, applied equally to the whole held pose
		# and muzzle. This never separates weapon/hands or lifts the feet.
		var breath := 1.0 + sin(time * TAU / 2.2) * .006
		rect.position.y = FOOT_Y + (rect.position.y - FOOT_Y) * breath
		rect.size.y *= breath
		muzzle.y = FOOT_Y + (muzzle.y - FOOT_Y) * breath
	return {"parts": [{"texture": WALK[index] if moving else IDLE[index], "region": region, "rect": rect, "upper": false}],
		"muzzle": muzzle, "direction": direction, "frame": index, "sheet": state, "source_sheet": frame.sheet,
		"angle": direction * STEP, "scale": scale_value}
