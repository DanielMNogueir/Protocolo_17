class_name P17WeaponVisual
extends RefCounted
## Read-only weapon presentation. Positions/damage/collision remain in simulation.gd.
const CYAN := Color("72eadf")
const CORE := Color("e9fff0")
static var _pulse: Texture2D
static var _flash: Texture2D

static func recoil_at(shot_age: float) -> float:
	return 1.6 * (1 - shot_age / .10) if shot_age >= 0 and shot_age < .10 else 0.0

static func draw_flash(canvas: Node2D, muzzle: Vector2, aim: Vector2, shot_age: float) -> void:
	if shot_age < 0 or shot_age >= .075:
		return
	_prepare_textures()
	var strength := 1 - shot_age / .075
	var size := Vector2(12, 10) * (.65 + strength * .35)
	_quad(canvas, _flash, Rect2(0, 0, 12, 10), Rect2(Vector2(-2, -size.y * .5), size), muzzle, aim.angle(), Color(1, 1, 1, strength))

static func draw_pulse(canvas: Node2D, bullet: Dictionary, time: float) -> void:
	_prepare_textures()
	var pos: Vector2 = bullet.pos
	var vel: Vector2 = bullet.vel
	var angle := vel.angle()
	var forward := vel.normalized()
	var source: Vector2 = bullet.get("source", pos - forward * 24.0)
	var travelled: float = maxf(0.0, (pos - source).dot(forward))
	# A new pulse grows from its source instead of drawing its tail through Lia's body.
	var length := minf(18.0, travelled)
	var flicker := 1.0 if int(time * 24) % 2 == 0 else .88
	if length > 0.0:
		_quad(canvas, _pulse, Rect2(18.0 - length, 0, length, 8), Rect2(-length, -4, length, 8), pos, angle, Color(1, 1, 1, flicker))
	if travelled > 14.0:
		canvas.draw_line(pos - forward * minf(24.0, travelled), pos - forward * 14.0, Color(CYAN, .25), 1)

static func _prepare_textures() -> void:
	if _pulse != null:
		return
	# Tiny native pixel patterns echo the atlas emitter. No filter or imported VFX pack.
	_pulse = _texture([
		"..................", "...........tttt...", ".....ttttcccccct..", "ttttccccwwwwwwwwwc",
		"ttttccccwwwwwwwwwc", ".....ttttcccccct..", "...........tttt...", ".................."])
	_flash = _texture([
		"....c.......", "....wc..c...", "..ccwwcc....", "...cwwwwcc..", "cwwwwwwwwwwc",
		"cwwwwwwwwwwc", "...cwwwwcc..", "..ccwwcc....", "....wc..c...", "....c......."])

static func _texture(rows: Array) -> Texture2D:
	var img := Image.create(str(rows[0]).length(), rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		assert(str(rows[y]).length() == img.get_width(), "Pixel sprite rows must have equal width")
		for x in str(rows[y]).length():
			var letter: String = rows[y][x]
			var color := Color.TRANSPARENT
			if letter == "w": color = CORE
			elif letter == "c": color = CYAN
			elif letter == "t": color = Color("267480", .7)
			img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)

static func _quad(canvas: Node2D, texture: Texture2D, region: Rect2, rect: Rect2, anchor: Vector2, angle: float, tint: Color) -> void:
	var corners := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	for i in corners.size():
		corners[i] = (anchor + corners[i].rotated(angle)).round()
	var uv := Rect2(region.position / texture.get_size(), region.size / texture.get_size())
	canvas.draw_polygon(corners, PackedColorArray([tint]), PackedVector2Array([uv.position, Vector2(uv.end.x, uv.position.y), uv.end, Vector2(uv.position.x, uv.end.y)]), texture)
