extends RefCounted

const Map = preload("res://scripts/core_map.gd")
const Boss = preload("res://scripts/core_boss.gd")
const HUD = preload("res://scripts/field_hud.gd")
const PowerArt = preload("res://scripts/power_art.gd")
const GALLERY: Texture2D = preload("res://assets/core/gallery.png")
const FRAMES = preload("res://assets/core/frames.gd")
const NIGHT: Texture2D = preload("res://assets/core/arena_night.png")
const DAWN: Texture2D = preload("res://assets/core/arena_dawn.png")
const CITY_NIGHT: Texture2D = preload("res://assets/core/city_below_night.png")
const CITY_DAWN: Texture2D = preload("res://assets/core/city_below_dawn.png")
const BOSS_SHEET: Texture2D = preload("res://assets/core/core_boss.png")
const PILLAR_SHEET: Texture2D = preload("res://assets/core/pillars.png")
const CONSOLE_SHEET: Texture2D = preload("res://assets/core/choice_consoles.png")
const SPARK_SHEET: Texture2D = preload("res://assets/power/spark.png")
const Actors = preload("res://scripts/actors_art.gd")
const Occlusion = preload("res://scripts/occlusion.gd")
const CITY: Texture2D = preload("res://assets/prologue/aurora_before.png")
const PINK := Color("e36b92")
const CYAN := HUD.CYAN
const GOLD := HUD.GOLD
const RED := HUD.RED
const SUN := Color("ffe4a8")
const INK := HUD.INK
const GALLERY_OUTLINES := [
	[Vector2(1045, 62), Vector2(1160, 67), Vector2(1208, 664), Vector2(1012, 664), Vector2(1017, 129)],
	[Vector2(458, 119), Vector2(782, 109), Vector2(838, 162), Vector2(838, 251), Vector2(880, 276),
		Vector2(875, 368), Vector2(808, 398), Vector2(464, 397), Vector2(402, 366), Vector2(397, 275), Vector2(445, 221)],
	[Vector2(93, 87), Vector2(204, 83), Vector2(249, 121), Vector2(237, 312), Vector2(157, 408), Vector2(134, 656), Vector2(94, 658)],
	[Vector2(147, 371), Vector2(259, 332), Vector2(290, 366), Vector2(275, 450), Vector2(190, 554), Vector2(149, 554)],
	[Vector2(538, 579), Vector2(742, 579), Vector2(812, 670), Vector2(470, 670)],
]



static func darkness(game: Node2D) -> float:
	if game.in_gallery: return 0.44
	var boss: Boss = game.boss
	match boss.phase:
		1: return 0.45
		2: return lerpf(0.45, 0.82, minf(1.0, boss.phase_time / 1.5)) - boss.dawn_amount * 0.27
		3: return 0.15
	if game.choice.result == "ai": return 0.3
	return 0.15


static func lights(game: Node2D) -> PackedVector4Array:
	var points := PackedVector4Array()
	if game.in_gallery:
		points.append(Vector4(Map.TERMINAL.x, Map.TERMINAL.y, 150, 0.82))
		points.append(Vector4(640, 638, 130, 0.64))
		points.append(Vector4(640, 168, 105, 0.6 if game.channel_read else 0.28))
	else:
		var boss: Boss = game.boss
		var center := boss.core_position()
		points.append(Vector4(center.x, center.y, 180, 0.75 if boss.phase != 2 else 0.2))
		if boss.phase != 2:
			for index in 8:
				var p := Map.ring(1.0, index * 45.0)
				points.append(Vector4(p.x, p.y - 18, 95, 0.63))
		else:
			for arc in boss.arcs:
				var p: Vector2 = arc.a.lerp(arc.b, 0.5)
				points.append(Vector4(p.x, p.y, 126, 0.7 if arc.state(boss.phase_time) == "active" else 0.2))
			if boss.dawn_amount > 0.0:
				points.append(Vector4(Boss.SUN.x, Boss.SUN.y, 670.0, boss.dawn_amount * 0.85))
	return points


static func world(game: Node2D) -> void:
	var offset: Vector2 = game.world_offset()
	var size := game.get_viewport_rect().size
	game.draw_rect(Rect2(Vector2.ZERO, size), Color("080d17"))
	game.draw_set_transform(offset)
	if game.in_gallery:
		_gallery(game)
	else:
		_arena(game)
	for instance in _entities(game):
		match instance.kind:
			"lia":
				var a = game.animation
				var action := "repair" if game.terminal_hold > 0.0 or game.choice.hold > 0.0 else "idle"
				var shot_age: float = game.loadout.fire_interval - game.fire_cd if game.fire_cd > 0.0 else -1.0
				Actors.draw_lia(game, game.pos, game.aim, a.elapsed, a.moving,
					game.invuln > 0.0 and int(game.clock * 16.0) % 2 == 0, game.dash_time > 0.0, action, shot_age)
			"spark":
				if instance.data.warp <= 0.0: _draw_spark(game, instance.data, game.clock)
			_:
				_fixture(game, instance)
	game.draw_set_transform(Vector2.ZERO)


static func _gallery(game: Node2D) -> void:
	game.draw_texture_rect(GALLERY, Rect2(Vector2.ZERO, Map.GALLERY_SIZE), false)
	for i in 6:
		var y := 184.0 + fposmod(i * 82.0 - game.clock * 30.0, 467.0)
		game.draw_rect(Rect2(1098, y, 7, 3), Color(CYAN, 0.36))
		game.draw_rect(Rect2(1140, y, 7, 3), Color(CYAN, 0.36))
	var at := Vector2(644, 191)
	if not game.channel_read:
		game.draw_dashed_line(at - Vector2(130, 0), at + Vector2(130, 0), Color(RED, 0.83), 3, 8, false, true)
	var alpha := 0.48 + minf(0.44, game.terminal_hold * 0.44)
	game.draw_line(Vector2(173, 426), Vector2(211, 394), Color(PINK, alpha), 3, true)


static func _arena(game: Node2D) -> void:
	var boss: Boss = game.boss
	var dawn := boss.dawn_amount
	var c := Map.CENTER
	var parallax: Vector2 = (game.camera - c) * 0.65
	var city := Rect2(c - Vector2(1350, 915) + parallax, Vector2(2700, 1830))
	game.draw_texture_rect(CITY_NIGHT, city, false)
	if dawn > 0.0: game.draw_texture_rect(CITY_DAWN, city, false, Color(1, 1, 1, dawn))
	game.draw_texture_rect(NIGHT, Map.ARENA_ART, false)
	if dawn > 0.0:
		var tint := Color(1.0, 0.78, 0.92, dawn) if game.choice.result == "ai" else Color(1, 1, 1, dawn)
		game.draw_texture_rect(DAWN, Map.ARENA_ART, false, tint)
	if boss.phase == 1:
		var pillars := Map.pillars()
		for index in pillars.size():
			var point := pillars[index]
			var start := point.move_toward(c, 43.0)
			var end := c.move_toward(point, 141.0)
			if boss.pillars[index].done:
				game.draw_line(start, end, Color(INK, 0.82), 10, true)
			else:
				game.draw_dashed_line(start, end, Color(CYAN, 0.5 + sin(game.clock * 3.0 + index) * 0.16), 3, 11, false, true)
	if boss.phase == 2:
		for arc in boss.arcs:
			var mode: String = arc.state(boss.phase_time)
			PowerArt.draw_pylon(game, arc.a, mode, arc.warning_amount(boss.phase_time), game.clock)
			PowerArt.draw_pylon(game, arc.b, mode, arc.warning_amount(boss.phase_time), game.clock)
	if boss.phase_time < 4.0 and boss.phase == 1:
		for orient in [[-90.0, "N · LABORATÓRIO"], [0.0, "L · ENERGIA"], [90.0, "S · RESÍDUOS"], [180.0, "O · ÁGUAS"]]:
			var at := Map.ring(0.8, orient[0])
			HUD.centered(game, orient[1], at, 13, Color(HUD.WHITE, 0.8))


static func _entities(game: Node2D) -> Array[Dictionary]:
	var entries: Array[Dictionary] = [{"kind": "lia", "pos": game.pos, "y": game.pos.y}]
	var phase: int = game.map_phase()
	if phase == 0:
		for i in Map.GALLERY_BLOCKS.size():
			var block: Rect2 = Map.GALLERY_BLOCKS[i]
			entries.append({"kind": "gallery", "index": i, "y": block.end.y, "pos": block.get_center()})
	else:
		entries.append(_entity("core", Map.CENTER, 0))
		match phase:
			1:
				var pillars := Map.pillars()
				for i in pillars.size(): entries.append(_entity("pillar", pillars[i], i))
			2:
				var mirrors := Map.mirrors()
				for i in mirrors.size(): entries.append(_entity("mirror", mirrors[i], i))
			4:
				for i in Map.CONSOLES.size(): entries.append(_entity("console", Map.CONSOLES[i], i))
	for enemy: Dictionary in game.enemies:
		entries.append({"kind": "spark", "pos": enemy.pos, "y": enemy.pos.y, "data": enemy})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.y < b.y)
	return entries


static func _entity(kind: String, pos: Vector2, index: int) -> Dictionary:
	return {"kind": kind, "pos": pos, "y": pos.y, "index": index}


static func _fixture(game: Node2D, data: Dictionary) -> void:
	var boss: Boss = game.boss
	var at: Vector2 = data.pos
	var index: int = data.index
	match data.kind:
		"gallery":
			_gallery_fixture(game, index)
		"core":
			_draw_core(game)
		"pillar":
			var pillar := boss.pillars[index]
			var frame := 3 if pillar.done else (2 if pillar.cooldown > 0.0 else (1 if pillar.running else 0))
			_frame(game, PILLAR_SHEET, "pillars", frame, at)
		"mirror":
			PowerArt.draw_mirror(game, at, boss.mirrors.orientation[index], boss.mirrors.turning[index],
				boss.dawn_amount > 0.0, boss.mirrors.aligned(index), game.clock)
			var normal := Vector2.from_angle(boss.mirrors.orientation[index] * PI / 4.0)
			game.draw_line(at, at + normal * 27.0, CYAN if boss.mirrors.aligned(index) else GOLD, 3, true)
		"console":
			var active: bool = game.choice.holding == ("human" if index == 0 else "ai")
			active = active or (not game.evidence.is_empty() and (game.evidence.side == "ai") == (index == 1))
			_frame(game, CONSOLE_SHEET, "choice_consoles", index * 2 + int(active), at)


static func _gallery_fixture(game: Node2D, index: int) -> void:
	var outline := PackedVector2Array(GALLERY_OUTLINES[index])
	var uv := PackedVector2Array()
	for point in outline:
		uv.append(point / Map.GALLERY_SIZE)
	game.draw_polygon(outline, PackedColorArray([Color.WHITE]), uv, GALLERY)


static func _draw_core(game: Node2D) -> void:
	var boss: Boss = game.boss
	var at := boss.core_position()
	var age: float = game.clock
	var frame := floori(age * 5.0) % 4
	match boss.phase:
		1: frame += 4 if boss.fallen_count() < 4 else 0
		2: frame += 8 if boss.burn > 0.0 else 0
		3: frame += 8
		4: frame = 15 if game.choice.result == "humanity" else 14
	if game.state == "collapse":
		at.y -= 70.0 * maxf(0.0, game.collapse / 1.2)
		frame = 12 if game.collapse > 0.6 else 13
	elif boss.phase <= 2:
		at.y += sin(age * 2.0) * 3.0
	elif game.choice.result == "ai" and game.ending.sequence == "resolution":
		at.y -= game.ending.age * 155.0
	var tint := CYAN if game.choice.result == "humanity" else PINK
	var charged := boss.warning > 0.0 or boss.burn > 0.0
	game.draw_colored_polygon(PowerArt._ellipse(Map.CENTER + Vector2(0, 22), 79, 25), Color(INK, 0.37))
	for i in range(4, 0, -1):
		game.draw_circle(at, 46 + 10 * i, Color(tint, (0.034 if charged else 0.012) * (5 - i)))
	_frame(game, BOSS_SHEET, "core_boss", frame, at)
	if boss.phase == 1:
		var strength := 1.0 - boss.fallen_count() / 4.0
		game.draw_arc(at, 84, age * 0.7, age * 0.7 + 5.7, 52, Color(CYAN, strength * 0.8), 3, true)


static func _spark_index(enemy: Dictionary, time: float) -> int:
	var heading := posmod(roundi(Vector2(enemy.facing).angle() / (PI / 4.0)), 8)
	return heading + 8 * (floori(time * 7.0) % 2)


static func _draw_spark(canvas: Node2D, enemy: Dictionary, time: float, ghost: bool = false) -> void:
	var at: Vector2 = enemy.pos
	var frame := _spark_index(enemy, time)
	if ghost:
		for n in 4:
			var halo := at + Vector2.from_angle(n * PI / 2.0) * 2.0
			_frame(canvas, SPARK_SHEET, "spark", frame, halo, Color(PINK, 0.66))
		_frame(canvas, SPARK_SHEET, "spark", frame, at, Color(1, 1, 1, 0.84))
		return
	_frame(canvas, SPARK_SHEET, "spark", frame, at, Color("ffccc4") if enemy.hurt > 0.0 else Color.WHITE)
	var hp := Rect2(at + Vector2(-15, -55), Vector2(30, 4))
	HUD.bar(canvas, hp, float(enemy.hp) / enemy.max_hp, CYAN)
	if enemy.warning > 0.0:
		canvas.draw_circle(at + Vector2(0, -60), 9, RED)
		HUD.centered(canvas, "!", at + Vector2(0, -56), 12, INK)


static func _frame(canvas: Node2D, texture: Texture2D, sheet: String, index: int, at: Vector2, tint: Color = Color.WHITE) -> void:
	var frame: Dictionary = FRAMES.DATA[sheet][index]
	var region: Array = frame.region
	var area: Array = frame.rect
	canvas.draw_texture_rect_region(texture, Rect2(at + Vector2(area[0], area[1]), Vector2(area[2], area[3])),
		Rect2(region[0], region[1], region[2], region[3]), tint)


static func effects(canvas: Node2D, game: Node2D) -> void:
	var boss: Boss = game.boss
	if not game.in_gallery:
		_attacks(canvas, game)
		if boss.phase == 2 and boss.burn > 0.0:
			for at in Map.mirrors():
				_beam(canvas, Boss.SUN, at, SUN)
				_beam(canvas, at, boss.core_position(), SUN)
		if game.choice.result == "ai" and game.ending.sequence == "resolution":
			_beam(canvas, Map.CENTER, Map.CENTER - Vector2(0, 1020), PINK, 30.0)
		if not game.evidence.is_empty():
			_evidence(canvas, game.evidence, game.clock)
	for shot: Dictionary in game.shots:
		var at: Vector2 = shot.pos
		var color := RED if shot.hostile else CYAN
		var tail: Vector2 = at - Vector2(shot.vel).normalized() * (8 if shot.hostile else 13)
		canvas.draw_line(tail, at, Color(color, 0.65), 3, true)
		canvas.draw_circle(at, 4.5 if shot.hostile else 2.8, color)
		canvas.draw_circle(at, 1.8, HUD.WHITE)
	for effect: Dictionary in game.effects:
		var fade: float = effect.left / effect.duration
		canvas.draw_arc(effect.pos, 5.0 + 37.0 * (1.0 - fade), 0, TAU, 24, Color(effect.color, fade * 0.8), 2, true)
	_ghosts(canvas, game)
	_interactables(canvas, game)


static func _attacks(canvas: Node2D, game: Node2D) -> void:
	var boss: Boss = game.boss
	var center := boss.core_position()
	if boss.attack == "laser" and (boss.warning > 0.0 or boss.fire_time > 0.0):
		var at := center + Vector2.from_angle(boss.laser_angle()) * 1150.0
		if boss.fire_time > 0.0:
			_beam(canvas, center, at, RED, 18.0)
		else:
			canvas.draw_line(center, at, Color(RED, 0.27 + 0.2 * (1.0 - boss.warning / boss.warning_length)), 18, true)
			canvas.draw_dashed_line(center, at, RED, 2, 12, false, true)
	elif boss.warning > 0.0:
		var amount := 1.0 - boss.warning / boss.warning_length
		canvas.draw_arc(center, 43 + amount * 41, 0.0, TAU, 38, Color(RED, 0.75), 3, true)
		var r := Vector2(0, -70)
		canvas.draw_colored_polygon(PackedVector2Array([center + r, center + r + Vector2(-10, 18),
			center + r + Vector2(10, 18)]), RED)
		HUD.centered(canvas, "!", center + r + Vector2(0, 15), 12, INK)
	if boss.phase == 2:
		for arc in boss.arcs:
			var mode: String = arc.state(boss.phase_time)
			if mode == "warning":
				canvas.draw_dashed_line(arc.a, arc.b, Color(GOLD, 0.42 + arc.warning_amount(boss.phase_time) * 0.4), 5, 11)
			elif mode == "active":
				PowerArt.draw_lightning(canvas, arc.a, arc.b, game.clock, 4, Color("9fe9ff"))


static func _beam(canvas: Node2D, a: Vector2, b: Vector2, color: Color, width: float = 7.0) -> void:
	canvas.draw_line(a, b, Color(color, 0.23), width * 2.1, true)
	canvas.draw_line(a, b, color, width, true)
	canvas.draw_line(a, b, color.lightened(0.65), maxf(2.0, width / 3.0), true)


static func _ghosts(canvas: Node2D, game: Node2D) -> void:
	var covers: Array[Dictionary] = []
	for entry in _entities(game):
		var at: Vector2 = entry.pos
		match entry.kind:
			"gallery":
				var outline: Array = GALLERY_OUTLINES[entry.index]
				var bounds := Rect2(outline[0], Vector2.ZERO)
				for vertex in outline: bounds = bounds.expand(vertex)
				covers.append({"bounds": bounds, "y": entry.y})
			"core": covers.append({"bounds": Rect2(at + Vector2(-63, -120), Vector2(126, 128)), "y": entry.y})
			"pillar", "mirror", "console":
				covers.append({"bounds": Rect2(at + Vector2(-45, -76), Vector2(90, 76)), "y": entry.y})
	var at: Vector2 = game.pos
	if Occlusion.is_hidden(Occlusion.lia_rect(at), at.y, covers):
		Occlusion.draw_lia_ghost(canvas, at, game.aim, game.animation.elapsed, game.animation.moving, "idle")
	for enemy: Dictionary in game.enemies:
		var point: Vector2 = enemy.pos
		if enemy.warp <= 0.0 and Occlusion.is_hidden(Occlusion.drone_rect(point, false), point.y, covers):
			_draw_spark(canvas, enemy, game.clock, true)


static func _interactables(canvas: Node2D, game: Node2D) -> void:
	match game.state:
		"gallery":
			if not game.channel_read and game.near(Map.TERMINAL, 78.0): HUD.interaction(canvas, Map.TERMINAL, game.clock)
		"arena":
			var index: int = game.pillar_in_reach() if game.boss.phase == 1 else -1
			if index >= 0: HUD.interaction(canvas, Map.pillars()[index], game.clock)
		"choice":
			var side: String = game.side_at_console()
			if not side.is_empty():
				var at: Vector2 = Map.CONSOLES[0 if side == "human" else 1]
				HUD.interaction(canvas, at, game.clock)
				if game.choice.hold > 0.0:
					canvas.draw_arc(at, 42, -PI / 2.0, -PI / 2.0 + TAU * game.choice.hold, 32, CYAN if side == "human" else PINK, 4, true)


static func _evidence(canvas: Node2D, data: Dictionary, time: float) -> void:
	var ai: bool = data.side == "ai"
	var accent := PINK if ai else CYAN
	var at: Vector2 = Map.CONSOLES[1 if ai else 0]
	var r := Rect2(at + Vector2(-100, -195), Vector2(200, 118))
	HUD.panel(canvas, r, accent)
	if ai and data.number == 1:
		for index in 2:
			var y := r.position.y + 33 + index * 38
			HUD.text(canvas, ["RIO −87%", "ENERGIA −94%"][index], Vector2(r.position.x + 16, y), 12, accent)
			HUD.bar(canvas, Rect2(r.position.x + 16, y + 5, 168, 8), [0.13, 0.06][index], accent)
	elif ai and data.number == 2:
		for i in 40:
			var dot := r.position + Vector2(20 + fposmod(i * 27 + time * 36.0, 160), 25 + (i * 17 % 60))
			canvas.draw_circle(dot, 2, accent)
		HUD.centered(canvas, "48.000 MORADORES", r.get_center() + Vector2(0, 43), 12, HUD.WHITE)
	elif ai:
		HUD.centered(canvas, "%d UNIDADES" % data.kills if data.number == 3 else "MAJOR 0", r.get_center(), 19, accent)
	else:
		if data.number == 1:
			canvas.draw_texture_rect(CITY, r.grow(-8), false, Color(CYAN, 0.7))
		elif data.number == 2:
			for i in 13:
				var p := r.position + Vector2(18 + 13 * i, 77.0 + sin(i * 2.0) * 7.0)
				canvas.draw_circle(p - Vector2(0, 15), 4, accent)
				canvas.draw_line(p - Vector2(0, 11), p + Vector2(0, 8), accent, 4)
		elif data.number == 3:
			for i in 7:
				var p := r.get_center() + Vector2.from_angle(i * TAU / 7.0) * Vector2(75, 42)
				canvas.draw_line(r.get_center(), p, PINK, 2, true)
				canvas.draw_circle(p, 4, accent)
		else:
			HUD.centered(canvas, "RIO · 2 ANOS", r.get_center() + Vector2(0, 18), 13, accent)
			canvas.draw_polyline(PackedVector2Array([r.position + Vector2(22, 48), r.position + Vector2(66, 19),
				r.position + Vector2(129, 39), r.position + Vector2(179, 53)]), accent, 2, true)
	for y in range(int(r.position.y) + 8, int(r.end.y) - 6, 4):
		canvas.draw_line(Vector2(r.position.x + 6, y), Vector2(r.end.x - 6, y), Color(accent, 0.12), 1)
