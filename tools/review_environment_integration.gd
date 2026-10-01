extends SceneTree
## Actual Compatibility-renderer review: movement uses the live simulation API.
const W = preload("res://scripts/world.gd")
const S = preload("res://scripts/simulation.gd")
const Energy = preload("res://scripts/energy_station.gd")
var game: Node2D
var capture_count := 0
var walk_count := 0
var failures: Array[String] = []
var output := "res://.runtime/integration_review"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if not OS.get_environment("P17_REVIEW_OUTPUT").is_empty(): output=OS.get_environment("P17_REVIEW_OUTPUT")
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_size=Vector2i(960,540)
	root.size=Vector2i(1440,810)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	game.clock=7
	game.pointer=Vector2(-100,-100)
	game.mode="play"
	var reviews := [
		["01_ponte_aberta",1,Vector2(770,925),Vector2(770,925)],
		["02_ponte_fechada",0,Vector2(770,1045),Vector2(770,925)],
		["03_ponte_horizontal",2,Vector2(1280,610),Vector2(1280,610)],
		["04_captacao",0,Vector2(680,1330),Vector2(590,1260)],
		["05_armazenamento",0,Vector2(300,1500),Vector2(300,1500)],
		["06_energia",1,Vector2(1030,450),Vector2(825,335)],
		["07_filtros",2,Vector2(1970,450),Vector2(1920,360)],
		["08_distribuicao",3,Vector2(1920,1170),Vector2(1840,1230)],
		["09_pier",0,Vector2(440,1740),Vector2(440,1630)],
		["10_tanque_atras",0,Vector2(997,1100),Vector2(925,1125)],
		["11_tanque_frente",0,Vector2(997,1168),Vector2(925,1125)],
		["12_tanque_lateral",0,Vector2(1048,1136),Vector2(925,1125)],
		["13_filtro_atras",2,Vector2(1670,305),Vector2(1710,350)],
		["14_filtro_frente",2,Vector2(1670,410),Vector2(1710,350)],
		["15_gerador_ligado",2,Vector2(1030,450),Vector2(825,335)],
		["16_gerador_atras",2,Vector2(918,355),Vector2(825,335)],
		["17_gerador_frente",2,Vector2(918,443),Vector2(825,335)],
		["18_gerador_lateral",2,Vector2(1043,390),Vector2(825,335)],
		["19_coletor_completo",3,Vector2(1760,1205),Vector2(1675,1120)],
		["20_ponte_oriental",3,Vector2(2040,925),Vector2(2040,925)],
	]
	for review in reviews:
		_prepare(review[1])
		game.sim.pos=review[2]
		game.camera_pos=review[3]
		game._clamp_camera()
		if not W.walkable(game.sim.pos,S.PLAYER_RADIUS,game.sim.stage):
			failures.append("Review position overlaps a solid: "+review[0])
		await _capture(review[0])
	# Walk the three bridge center lanes in both directions, with rendered frames.
	for index in range(W.BRIDGES.size()):
		_prepare(index+1)
		var bridge: Rect2=W.BRIDGES[index]
		var direction:=Vector2.DOWN if bridge.size.y>bridge.size.x else Vector2.RIGHT
		var extent: float=(bridge.size.y if bridge.size.y>bridge.size.x else bridge.size.x)*0.5+28
		await _walk(bridge.get_center()-direction*extent,bridge.get_center()+direction*extent,"ponte_%d_ida"%index)
		await _walk(bridge.get_center()+direction*extent,bridge.get_center()-direction*extent,"ponte_%d_volta"%index)
	# Also render Lia moving around individual industrial bases and storage groups.
	_prepare(3)
	var walk_records: Array=[W.props()[0],W.props()[2],W.props()[3],W.props()[5],W.building_objects()[2],W.building_objects()[4]]
	for base in Energy.COLLISION_RECTS: walk_records.append({"collision_rect":base})
	for record in walk_records:
		var r: Rect2=record.collision_rect.grow(S.PLAYER_RADIUS+4)
		var points: Array[Vector2]=[r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)]
		for index in range(4):
			var allowed:=true
			for sample in range(21):
				if not W.walkable(points[index].lerp(points[(index+1)%4],sample/20.0),S.PLAYER_RADIUS,3): allowed=false
			if allowed: await _walk(points[index],points[(index+1)%4],"base")
	if walk_count<20: failures.append("Rendered movement coverage is incomplete")
	print("RENDERED_ENVIRONMENT_REVIEW_%s: %d captures; %d walks; %d failures"%["OK" if failures.is_empty() else "FAILED",capture_count,walk_count,failures.size()])
	for failure in failures: push_error(failure)
	# Finish destruction before asking SceneTree to quit; queued destruction can
	# overlap the renderer/audio shutdown in a hidden automated review window.
	game.free()
	game=null
	for cleanup in range(5): await process_frame
	quit(0 if failures.is_empty() else 1)

func _prepare(stage: int) -> void:
	game.sim.start(stage)
	game.sim.enemies.clear()
	game.sim.velocity=Vector2.ZERO
	game.sim.tick(0.001,Vector2.ZERO,game.sim.pos+Vector2.DOWN,false,false,false)
	game._update_energy_station(2)

func _walk(a: Vector2,b: Vector2,label: String) -> void:
	game.sim.pos=a
	game.sim.velocity=Vector2.ZERO
	for frame in range(360):
		if game.sim.pos.distance_to(b)<3: break
		var movement: Vector2=(b-game.sim.pos).normalized()
		game.sim.tick(1.0/60,movement,b,false,false,false)
		game.lia_animation.advance(1.0/60,game.sim.velocity,game.sim.dash_time>0)
		game.camera_pos=game.sim.pos
		game._clamp_camera()
		if not W.walkable(game.sim.pos,S.PLAYER_RADIUS,game.sim.stage):
			failures.append("Lia entered a footprint during "+label)
		game.queue_redraw()
		await process_frame
	if game.sim.pos.distance_to(b)>5: failures.append("Lia got stuck during "+label)
	walk_count+=1
	print("WALK ",label," distance_remaining=",game.sim.pos.distance_to(b))

func _capture(label: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var path:=output+"/"+label+".png"
	if root.get_texture().get_image().save_png(path)!=OK: failures.append("Cannot save "+path)
	capture_count+=1
	print("Captured ",path)
