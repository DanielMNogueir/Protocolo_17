class_name P17EnergyStation
extends P17WorldStructure
## First modular structure proof of concept.
## The node scene is editor-ready; these draw methods bridge it into the alpha's
## existing immediate-mode renderer without replacing combat or movement.

const STRUCTURES: Texture2D = preload("res://assets/station/structures_atlas.png")
const VEGETATION: Texture2D = preload("res://assets/station/vegetation_atlas.png")

const WORLD_ORIGIN := Vector2(835.0, 420.0)
const INTERACTION_POINT := Vector2(1012.0, 410.0)
const SORT_Y := 420.0
const Art = preload("res://scripts/station_art.gd")
const Objectives = preload("res://scripts/objective_visual.gd")
const CONTROL_CROP: Rect2 = Art.STRUCTURE_CROPS[3]
const GENERATOR_CROP: Rect2 = Art.STRUCTURE_CROPS[5]
const MOSS_CROP := Rect2(35, 514, 279, 258)
const CONTROL_VISUAL := Rect2(640,414-210.0*421.0/440.0,210,210.0*421.0/440.0)
const GENERATOR_VISUAL := Rect2(835,422-164.0*351.0/392.0,164,164.0*351.0/392.0)
const TERMINAL_VISUAL := Rect2(990,316,44,82)
const COLLISION_RECTS: Array[Rect2] = [
	Rect2(650, 372, 188, 49),
	Rect2(841, 381, 151, 40),
	Rect2(1000,386,24,8),
]


func _init() -> void:
	structure_id = &"energy_station"
	interaction_prompt = "[E] REPARAR SISTEMA"
	startup_duration = 1.35
	interaction_radius = 84.0


func draw_foundation(canvas: Node2D, time: float) -> void:
	# Separate feet and buried cable runs avoid the old framed-PNG silhouette.
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(644, 383), Vector2(824, 383), Vector2(842, 421), Vector2(657, 428)
	]), Color(0.025, 0.055, 0.06, 0.35))
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(843, 390), Vector2(987, 390), Vector2(1000, 422), Vector2(850, 429)
	]), Color(0.025, 0.055, 0.06, 0.38))
	canvas.draw_line(Vector2(811, 414), Vector2(1005, 414), Color("243b40"), 8.0)
	canvas.draw_line(Vector2(811, 412), Vector2(1005, 412), Color("a2734d"), 3.0)
	canvas.draw_line(Vector2(736, 414), Vector2(736, 455), Color("243b40"), 7.0)
	canvas.draw_line(Vector2(738, 414), Vector2(738, 455), Color("8d6548"), 2.0)
	var moss_dest := Rect2(Vector2(637, 393), Vector2(57, 52))
	canvas.draw_texture_rect_region(VEGETATION, moss_dest, MOSS_CROP, Color(0.72, 0.82, 0.66, 0.72))
	if structure_state != StructureState.OFFLINE:
		var pulse_x := 819.0 + fposmod(time * 42.0, 174.0)
		canvas.draw_rect(Rect2(pulse_x, 409, 9, 3), Color("67e2ce", 0.78))
	Objectives.draw_foundation(canvas,INTERACTION_POINT,1,is_online(),time)


func sortable_parts() -> Array[Dictionary]:
	return [{"index":0,"y":COLLISION_RECTS[0].end.y},{"index":1,"y":COLLISION_RECTS[1].end.y},{"index":2,"y":COLLISION_RECTS[2].end.y}]

func draw_body(canvas: Node2D, time: float) -> void:
	for part in sortable_parts(): draw_part(canvas,part.index,time)

func draw_part(canvas: Node2D, part: int, time: float) -> void:
	var tint := Color("98a4a0") if structure_state == StructureState.OFFLINE else Color.WHITE
	var shake_offset := Vector2.ZERO
	if structure_state == StructureState.STARTING:
		shake_offset.x = round(sin(time * 39.0) * (1.0 - startup_progress()))
	var control_dest := Rect2(CONTROL_VISUAL.position+shake_offset,CONTROL_VISUAL.size)
	var generator_dest := Rect2(GENERATOR_VISUAL.position+shake_offset,GENERATOR_VISUAL.size)
	if part == 0:
		canvas.draw_texture_rect_region(STRUCTURES,control_dest,CONTROL_CROP,tint)
		_draw_fan(canvas,Vector2(789,306)+shake_offset,time)
	elif part == 1:
		Art.draw_structure(canvas,5,generator_dest,tint)
	else:
		Objectives.draw_body(canvas,INTERACTION_POINT,1,is_online(),time)


func draw_effects(canvas: Node2D, time: float) -> void:
	if structure_state == StructureState.STARTING:
		var radius := 24.0 + startup_progress() * 80.0
		canvas.draw_arc(Vector2(918, 337), radius, 0, TAU, 28, Color("87f2d9", 0.45 * (1.0 - startup_progress())), 2.0)
	if structure_state == StructureState.ONLINE:
		for index in 3:
			var phase := fposmod(time * (12.0 + index * 1.7) + index * 17.0, 42.0)
			var vapor := Vector2(958 + index * 4 + sin(time * 2.0 + index) * 3.0, 273 - phase)
			canvas.draw_rect(Rect2(vapor, Vector2(2, 4)), Color("c5e8db", 0.30 * (1.0 - phase / 42.0)))
	elif int(time * 2.0) % 7 == 0:
		var spark := Vector2(973, 354) + Vector2(sin(time * 31.0), cos(time * 23.0)) * 5.0
		canvas.draw_line(spark, spark + Vector2(3, -5), Color("eaa077", 0.75), 1.0)


func _draw_fan(canvas: Node2D, center: Vector2, time: float) -> void:
	var active_speed := 4.2 if structure_state == StructureState.ONLINE else (1.8 * startup_progress() if structure_state == StructureState.STARTING else 0.0)
	var angle := time * active_speed
	canvas.draw_circle(center, 11.0, Color("182f36", 0.86))
	canvas.draw_arc(center, 10.0, 0, TAU, 16, Color("b79667"), 2.0)
	for blade in 4:
		var direction := Vector2.from_angle(angle + blade * PI * 0.5)
		canvas.draw_line(center + direction * 2.0, center + direction * 8.0, Color("65b7ad") if active_speed > 0.0 else Color("61797a"), 3.0)
	canvas.draw_circle(center, 2.0, Color("d3bd83"))
