extends RefCounted

const Map = preload("res://scripts/core_map.gd")
const Boss = preload("res://scripts/core_boss.gd")
const HUD = preload("res://scripts/field_hud.gd")
const PowerArt = preload("res://scripts/power_art.gd")
const PROPS: Texture2D = preload("res://assets/power/props_atlas.png")
const TERMINALS: Texture2D = preload("res://assets/power/terminals_atlas.png")
const Actors = preload("res://scripts/actors_art.gd")
const Occlusion = preload("res://scripts/occlusion.gd")
const CITY: Texture2D = preload("res://assets/prologue/aurora_before.png")
const PINK := Color("e36b92")
const CYAN := HUD.CYAN
const GOLD := HUD.GOLD
const RED := HUD.RED
const SUN := Color("ffe4a8")
const STEEL := Color("34464a")
const JOINT := Color("566b6b")
const BRASS := Color("b08a4a")
const INK := HUD.INK
const ARMOR := Color("6b8383")


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
		points.append(Vector4(640, 727, 130, 0.64))
		points.append(Vector4(640, 85, 105, 0.6 if game.channel_read else 0.28))
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
				if instance.data.warp <= 0.0: PowerArt.draw_enemy(game, instance.data, game.clock)
			_:
				_fixture(game, instance)
	game.draw_set_transform(Vector2.ZERO)


static func _gallery(game: Node2D) -> void:
	var extent := Rect2(Vector2.ZERO, Map.GALLERY_SIZE)
	game.draw_rect(extent, Color("101b24"))
	var tile_rect := extent.grow(-18)
	game.draw_rect(tile_rect, Color("293b40"))
	PowerArt._draw_tiles(game, tile_rect, 64.0, JOINT)
	game.draw_rect(tile_rect, BRASS.darkened(0.35), false, 3)
	PowerArt._draw_hazard(game, Rect2(558, 104, 164, 10))
	var gate_color := CYAN if game.channel_read else RED
	game.draw_rect(Map.STAIRS, INK)
	for i in 5:
		var step := Rect2(Map.STAIRS.position + Vector2(6, 6 + i * 12), Vector2(148, 10))
		game.draw_rect(step, STEEL.lightened((4 - i) * 0.045))
		game.draw_line(step.position, step.position + Vector2(step.size.x, 0), gate_color.darkened(0.25), 2)
	if not game.channel_read:
		game.draw_line(Vector2(558, 110), Vector2(722, 110), RED, 4)
	game.draw_texture_rect_region(TERMINALS, Rect2(588, 691, 104, 84),
		_atlas_region(TERMINALS, Vector2i(3, 0), Vector2i(4, 1)))
	game.draw_line(Vector2(640, 275), Vector2(640, 665), Color(CYAN, 0.18), 2)
	for i in 8:
		var y := 275.0 + 45.0 * i
		game.draw_rect(Rect2(632, y, 16, 2), Color(CYAN, 0.24))


static func _arena(game: Node2D) -> void:
	var boss: Boss = game.boss
	var dawn := boss.dawn_amount
	var c := Map.CENTER
	var parallax: Vector2 = (game.camera - c) * 0.65
	var city := Rect2(c - Vector2(1350, 915) + parallax, Vector2(2700, 1830))
	var shade := Color("28435e").lerp(Color("b0886b"), dawn)
	if game.choice.result == "ai": shade = shade.lerp(PINK, 0.35)
	game.draw_texture_rect(CITY, city, false, shade)
	for i in 5:
		var x := fposmod(i * 511.0 + game.clock * 8.0, 2420.0)
		var p := Vector2(x - 230.0, 300.0 + i * 183.0) + parallax
		game.draw_colored_polygon(PowerArt._ellipse(p, 170 + 23 * i, 40 + i * 5), Color("c6ced1", 0.08))
	var radii := Map.RADII
	game.draw_colored_polygon(PowerArt._ellipse(c + Vector2(0, 30), radii.x + 4.0, radii.y), Color("16252b"))
	game.draw_colored_polygon(PowerArt._ellipse(c, radii.x, radii.y), STEEL)
	for fraction in [0.32, 0.51, 0.7, 0.88]:
		game.draw_polyline(_ring(fraction), JOINT, 2, true)
	for i in 24:
		var angle := i * 15.0
		game.draw_line(Map.ring(0.16, angle), Map.ring(0.98, angle), JOINT.darkened(0.21), 2)
	for i in 90:
		game.draw_line(Map.ring(0.94, i * 4.0), Map.ring(0.94, i * 4.0 + 2.4), GOLD.darkened(0.2), 4)
	for i in 12:
		var step := Rect2(895, 1198 + i * 5, 130, 5)
		game.draw_rect(step, STEEL.darkened(0.12 + i * 0.02))
		game.draw_line(step.position, step.position + Vector2(step.size.x, 0), JOINT, 1)
	game.draw_polyline(_ring(1.0), INK, 6, true)
	var rails := _ring(1.0, Vector2(0, -21))
	game.draw_polyline(rails, BRASS, 3, true)
	for i in 48:
		var at := Map.ring(1.0, i * 7.5)
		if absf(i * 7.5 - 90.0) < 8.0: continue
		game.draw_line(at, at + Vector2(0, -26), BRASS, 3)
		if i % 6 == 0 and boss.phase != 2:
			game.draw_circle(at + Vector2(0, -24), 8, Color(GOLD, 0.26))
			game.draw_rect(Rect2(at + Vector2(-3, -26), Vector2(6, 4)), SUN)
	if boss.phase == 1:
		var pillars := Map.pillars()
		for index in pillars.size():
			var point := pillars[index]
			game.draw_line(point, c, INK, 10, true)
			if not boss.pillars[index].done:
				game.draw_dashed_line(point, c, Color(CYAN, 0.5 + sin(game.clock * 3.0 + index) * 0.16), 3, 11, false, true)
	if boss.phase == 2:
		for arc in boss.arcs:
			var mode: String = arc.state(boss.phase_time)
			PowerArt.draw_pylon(game, arc.a, mode, arc.warning_amount(boss.phase_time), game.clock)
			PowerArt.draw_pylon(game, arc.b, mode, arc.warning_amount(boss.phase_time), game.clock)
	if boss.phase_time < 4.0 and boss.phase == 1:
		for orient in [[-90.0, "N · LABORATÓRIO"], [0.0, "L · ENERGIA"], [90.0, "S · RESÍDUOS"], [180.0, "O · ÁGUAS"]]:
			var at := Map.ring(0.8, orient[0])
			HUD.centered(game, orient[1], at, 13, Color(HUD.WHITE, 0.8))


static func _ring(fraction: float, offset: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 97:
		var angle := i * 3.75
		var point := Map.ring(fraction, angle)
		if offset != Vector2.ZERO and absf(angle - 90.0) < 6.0:
			points.append(point)
		else:
			points.append(point + offset)
	return points


static func _entities(game: Node2D) -> Array[Dictionary]:
	var entries: Array[Dictionary] = [{"kind": "lia", "pos": game.pos, "y": game.pos.y}]
	var phase: int = game.map_phase()
	if phase == 0:
		for i in Map.GALLERY_BLOCKS.size():
			var block: Rect2 = Map.GALLERY_BLOCKS[i]
			entries.append({"kind": "gallery", "rect": block, "index": i, "y": block.end.y, "pos": block.get_center()})
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
			_gallery_fixture(game, data.rect, index)
		"core":
			_draw_core(game)
		"pillar":
			var down := boss.pillars[index].done
			_prop(game, at, Vector2i(3 if down else 2, 3), Vector2(107, 54 if down else 106))
			if not down:
				game.draw_circle(at + Vector2(0, -67), 6, Color(CYAN, 0.55))
		"mirror":
			PowerArt.draw_mirror(game, at, boss.mirrors.orientation[index], boss.mirrors.turning[index],
				boss.dawn_amount > 0.0, boss.mirrors.aligned(index), game.clock)
			var normal := Vector2.from_angle(boss.mirrors.orientation[index] * PI / 4.0)
			game.draw_line(at, at + normal * 27.0, CYAN if boss.mirrors.aligned(index) else GOLD, 3, true)
		"console":
			_prop(game, at, Vector2i(1, 2 if index == 0 else 3), Vector2(104, 76))
			var accent := CYAN if index == 0 else PINK
			game.draw_rect(Rect2(at + Vector2(-12, -43), Vector2(24, 5)), accent)


static func _gallery_fixture(game: Node2D, r: Rect2, index: int) -> void:
	var top := r
	top.position.y -= 29.0
	game.draw_rect(r, INK)
	game.draw_rect(top, STEEL)
	game.draw_rect(top, JOINT, false, 2)
	match index:
		0:
			game.draw_rect(top.grow(-8), Color("293034"))
			for i in 12:
				var y := fposmod(50.0 * i - game.clock * 30.0, top.size.y - 22.0)
				var crate := Rect2(top.position + Vector2(21, y + 5), Vector2(48, 16))
				var shades := [Color("8d9699"), Color("3f9a8e"), Color("a9e3ee")]
				game.draw_rect(crate.grow(3), INK)
				game.draw_rect(crate, shades[i % 3])
		1:
			game.draw_rect(top.grow(-16), INK)
			for i in 4:
				var bend := sin(game.clock * 1.7 + i) * 2.0
				var p := top.position + Vector2(38 + 53 * i, 47)
				game.draw_line(p, p + Vector2(17, 60 + bend), BRASS, 8)
		2:
			for i in 9:
				var row := Rect2(top.position + Vector2(8, i * 53 + 7), Vector2(104, 45))
				game.draw_rect(row, INK)
				for j in 5:
					var alpha := 0.45 + 0.4 * sin(game.clock * 4.0 + i * 3.0 + j)
					game.draw_circle(row.position + Vector2(11 + j * 16, 14), 2, Color(CYAN, alpha))
		3:
			_prop(game, Map.TERMINAL - Vector2(0, 21), Vector2i(1, 3), Vector2(112, 86))
			game.draw_rect(Rect2(318, 388, 34, 10), Color(PINK, 0.5 + game.terminal_hold * 0.4))


static func _prop(canvas: Node2D, at: Vector2, cell: Vector2i, size: Vector2) -> void:
	canvas.draw_texture_rect_region(PROPS, Rect2(at - Vector2(size.x * 0.5, size.y * 0.88), size),
		_atlas_region(PROPS, cell, Vector2i(4, 4)))


static func _atlas_region(texture: Texture2D, cell: Vector2i, grid: Vector2i) -> Rect2:
	var size := texture.get_size() / Vector2(grid)
	return Rect2(Vector2(cell) * size, size).grow(-2)


static func _draw_core(game: Node2D, silhouette: bool = false) -> void:
	var boss: Boss = game.boss
	var at := boss.core_position()
	var at_rest: bool = boss.phase >= 4 and game.choice.result != "ai"
	var exposed := boss.phase >= 3
	if game.state == "collapse":
		at.y -= 70.0 * maxf(0.0, game.collapse / 1.2)
	elif boss.phase <= 2:
		at.y += sin(game.clock * 2.0) * 3.0
	elif game.choice.result == "ai" and game.ending.sequence == "resolution":
		at.y -= game.ending.age * 155.0
	var tint := CYAN if game.choice.result == "humanity" else PINK
	if silhouette: tint = HUD.WHITE
	var charged := boss.warning > 0.0 or boss.burn > 0.0
	if not silhouette:
		game.draw_colored_polygon(PowerArt._ellipse(Map.CENTER + Vector2(0, 22), 83, 27), Color(INK, 0.7))
	for i in range(5, 0, -1):
		game.draw_circle(at, 46 + 10 * i, Color(tint, (0.035 if charged else 0.018) * (6 - i)))
	game.draw_circle(at, 47, INK if not silhouette else Color(tint, 0.3))
	game.draw_circle(at, 42, Color("22363d") if not silhouette else INK)
	for i in 4:
		var axis := Vector2.from_angle(i * TAU / 4.0 + 0.78)
		var mid := at + axis * (46.0 if exposed else 29.0) + Vector2(0, 12.0 if at_rest and i < 2 else 0.0)
		var edge := axis.orthogonal()
		var petal := PackedVector2Array([mid + axis * 22, mid + edge * 22, mid - axis * 14,
			mid - edge * 22])
		game.draw_colored_polygon(petal, Color(tint, 0.55) if silhouette else ARMOR.darkened(0.14 * (i % 2)))
		game.draw_line(petal[1], petal[0], BRASS if not silhouette else tint, 3, true)
	game.draw_circle(at, 25 if exposed else 13, tint)
	game.draw_circle(at, 10 if exposed else 5, Color("fff0df"))
	if boss.phase == 1:
		var strength := 1.0 - boss.fallen_count() / 4.0
		game.draw_arc(at, 67.0, game.clock * 0.7, game.clock * 0.7 + 5.7, 52, Color(CYAN, strength * 0.8), 3, true)
	elif not at_rest:
		for i in 2:
			var spin: float = game.clock * (1.0 if i == 0 else -0.8)
			game.draw_arc(at, 56.0 + i * 8.0, spin, spin + PI * 1.42, 40, Color(tint, 0.68), 2, true)


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
			"gallery": covers.append({"bounds": Rect2(entry.rect).grow(9).grow_side(SIDE_TOP, 25), "y": entry.y})
			"core": covers.append({"bounds": Rect2(at + Vector2(-63, -120), Vector2(126, 128)), "y": entry.y})
			"pillar", "mirror", "console":
				covers.append({"bounds": Rect2(at + Vector2(-45, -76), Vector2(90, 76)), "y": entry.y})
	var at: Vector2 = game.pos
	if Occlusion.is_hidden(Occlusion.lia_rect(at), at.y, covers):
		Occlusion.draw_lia_ghost(canvas, at, game.aim, game.animation.elapsed, game.animation.moving, "idle")
	for enemy: Dictionary in game.enemies:
		var point: Vector2 = enemy.pos
		if enemy.warp <= 0.0 and Occlusion.is_hidden(Occlusion.drone_rect(point, false), point.y, covers):
			Occlusion.draw_drone_ghost(canvas, enemy, game.clock)


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
