extends RefCounted
## Directional illustrated machines and combat feedback. No simulation writes.
static var _textures: Dictionary = {}
static var _data: Dictionary = {}
const MAGENTA := Color("f277cc")
const AMBER := Color("ffe2a0")

static func prepare() -> void:
	if not _data.is_empty(): return
	_data = load("res://assets/enemies/frames.gd").DATA
	for kind in ["scout", "sentry", "rammer", "boss"]:
		_textures[kind] = load("res://assets/enemies/" + kind + ".png")

static func frame_for(enemy: Dictionary, time: float) -> Dictionary:
	prepare()
	var kind: String = enemy.get("kind", "scout")
	var aim: Vector2 = enemy.get("facing", enemy.get("aim", Vector2.DOWN))
	var direction := posmod(int(floor((aim.angle() + PI / 8.0) / (PI / 4.0))), 8)
	var fps := 12.0 if kind == "scout" else (10.0 if enemy.get("phase", "idle") == "charge" else 6.0)
	var cycle := int(time * fps) % 2 if kind == "scout" or enemy.get("moving", false) or enemy.get("phase", "idle") in ["charge", "windup"] else 0
	return _data[kind].frames[direction + cycle * 8]

static func draw(canvas: Node2D, enemy: Dictionary, fallback_time: float) -> void:
	var time: float = enemy.get("anim_time", fallback_time)
	var frame := frame_for(enemy, time)
	var kind: String = enemy.get("kind", "scout")
	var boss := kind == "boss"
	var origin: Vector2 = Vector2(enemy.pos).round()
	var foot := 29.0 if boss else 14.0
	var width := 38.0 if boss else 17.0
	var shadow := PackedVector2Array()
	for i in 16:
		shadow.append(origin + Vector2(0, foot) + Vector2(cos(i * TAU / 16) * width, sin(i * TAU / 16) * (5 if boss else 3)))
	canvas.draw_colored_polygon(shadow, Color("06151b", .42))
	var bob := sin(time * (7 if kind == "scout" else 5)) * (1.5 if kind == "scout" else .35)
	var aim: Vector2 = enemy.get("facing", enemy.get("aim", Vector2.DOWN))
	var attack_age: float = enemy.get("attack_age", 99.0)
	var recoil := maxf(0.0, 1.0 - attack_age / .18) * (3.0 if boss else 1.8)
	var offset := origin + Vector2(0, foot - (4.0 if kind == "scout" else 0.0) + bob) - aim * recoil
	if enemy.get("phase", "idle") == "charge":
		offset += aim * 2.0
	var rect := Rect2(frame.rect[0], frame.rect[1], frame.rect[2], frame.rect[3])
	var region := Rect2(frame.region[0], frame.region[1], frame.region[2], frame.region[3])
	var warning: float = float(enemy.get("warning", 0.0))
	var tint := Color.WHITE
	if float(enemy.get("hurt", 0.0)) > 0:
		tint = Color(2.0, 1.4, 1.5)
	elif warning > 0:
		tint = Color(1.0 + .22 * absf(sin(time * 25)), 1.0, .92)
	if enemy.get("phase", "idle") == "charge":
		for i in range(3, 0, -1):
			canvas.draw_texture_rect_region(_textures[kind], Rect2(rect.position + offset - aim * i * 7.0, rect.size), region, Color(1, .6, .4, .07 * (4 - i)))
	canvas.draw_texture_rect_region(_textures[kind], Rect2(rect.position + offset, rect.size), region, tint)
	if frame.has_core and (warning > 0 or attack_age < .16):
		var core := offset + Vector2(frame.core[0], frame.core[1])
		var energy := absf(sin(time * 24)) if warning > 0 else 1.0 - attack_age / .16
		canvas.draw_circle(core, (4.0 if boss else 2.5) + energy * 2.0, Color(MAGENTA, .18 + .18 * energy))
		canvas.draw_line(core - Vector2(3, 0), core + Vector2(3, 0), Color(AMBER, energy), 1)
	if float(enemy.hp) / maxf(1, float(enemy.max_hp)) < .4 and int(time * 12) % 5 == 0:
		var spark := offset + Vector2(-7, -16 if boss else -9)
		canvas.draw_line(spark, spark + Vector2(4, -5), AMBER, 1)
		canvas.draw_line(spark + Vector2(3, -5), spark + Vector2(7, -7), MAGENTA, 1)

static func draw_destroyed(canvas: Node2D, wreck: Dictionary) -> void:
	var age: float = wreck.death_age
	var frame := frame_for(wreck, wreck.anim_time)
	var kind: String = wreck.kind
	var size := 1.7 if kind == "boss" else 1.0
	var origin: Vector2 = wreck.pos
	var rect := Rect2(frame.rect[0], frame.rect[1], frame.rect[2], frame.rect[3])
	var region := Rect2(frame.region[0], frame.region[1], frame.region[2], frame.region[3])
	var fade := clampf(1.0 - age / 1.05, 0, 1)
	var parts := 4 if kind == "boss" else 3
	var texture: Texture2D = _textures[kind]
	for y in parts:
		for x in parts:
			var seed_value: float = x * 7.3 + y * 2.7 + float(wreck.id)
			var direction := Vector2(x - (parts - 1) * .5, y - (parts - 1) * .5).normalized().rotated(sin(seed_value) * .45)
			var displacement := direction * age * (22.0 + 9.0 * cos(seed_value)) * size + Vector2(0, age * age * 45 - age * 15)
			var piece := Rect2(rect.position + Vector2(x, y) * rect.size / parts + origin + Vector2(0, 14 * size) + displacement, rect.size / parts)
			var uv := Rect2((region.position + Vector2(x, y) * region.size / parts) / texture.get_size(), region.size / parts / texture.get_size())
			var corners := PackedVector2Array([piece.position, Vector2(piece.end.x, piece.position.y), piece.end, Vector2(piece.position.x, piece.end.y)])
			for i in corners.size():
				corners[i] = piece.get_center() + (corners[i] - piece.get_center()).rotated(sin(seed_value) * age * 4.0)
			canvas.draw_polygon(corners, PackedColorArray([Color(1.4 if age < .08 else .6, .7, .8, fade)]), PackedVector2Array([uv.position, Vector2(uv.end.x, uv.position.y), uv.end, Vector2(uv.position.x, uv.end.y)]), texture)
	for i in 10:
		var direction := Vector2.from_angle(i * TAU / 10.0 + float(wreck.id))
		var point := origin + direction * age * 55.0 * size + Vector2(0, age * age * 30 - 8)
		canvas.draw_line(point, point - direction * 4.0 * fade, Color(AMBER if i % 2 == 0 else MAGENTA, fade), 1.5)
	if age < .2:
		canvas.draw_arc(origin + Vector2(0, -6), (3.0 + age * 95.0) * size, 0, TAU, 24, Color(MAGENTA, (1 - age / .2) * .65), 2)
