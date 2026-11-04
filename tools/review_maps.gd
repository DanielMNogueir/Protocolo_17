extends SceneTree
const MapUI=preload("res://scripts/field_map.gd")
class Shell extends "res://scripts/main.gd":
	func _save_checkpoint() -> void: pass
	func _read_checkpoint() -> Dictionary: return {}
	func _load_settings() -> void: pass
	func _save_settings() -> void: pass
var game: Node2D
var out:=OS.get_environment("P17_MAP_OUTPUT")
var captures:=0
var checks:=0
var failures: Array[String]=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label); push_error(label)
func key(code: Key) -> void:
	var e:=InputEventKey.new()
	e.physical_keycode=code
	e.pressed=true
	game._unhandled_input(e)
func close_click() -> void:
	var e:=InputEventMouseButton.new()
	e.button_index=MOUSE_BUTTON_LEFT
	e.pressed=true
	e.position=MapUI.close_rect(game.get_viewport_rect().size).get_center()
	game._unhandled_input(e)
func capture(label: String) -> void:
	game.queue_redraw()
	if "_hud" in game: game._hud.queue_redraw()
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	var size: Vector2=game.get_viewport_rect().size
	var parts:=MapUI.layout(size)
	var bounds:=Rect2(Vector2.ZERO,size)
	for name in ["frame","canvas","sidebar","footer"]: check(bounds.encloses(parts[name]),"Panel fits: "+name)
	check(not parts.frame.intersects(parts.sidebar),"Map and sidebar are separate")
	check(not parts.frame.intersects(parts.footer),"Map and legend are separate")
	check(bounds.encloses(MapUI.close_rect(size)),"Return control fits")
	check(root.get_texture().get_image().save_png(out.path_join(label+".png"))==OK,"Capture saved")
	captures+=1
func resolution(value: Vector2i) -> void:
	root.content_scale_size=Vector2i(1280,720) if value.x==1280 else Vector2i(960,540)
	root.size=value
func run() -> void:
	if out.is_empty(): out=ProjectSettings.globalize_path("user://map-review")
	DirAccess.make_dir_recursive_absolute(out)
	game=Shell.new()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	game.clock=12
	game.dialogue.clear()
	game.toast_time=0
	game.pointer=Vector2(-100,-100)
	for size in [Vector2i(960,540),Vector2i(1440,810),Vector2i(1280,720)]:
		resolution(size)
		for stage in 4:
			game.sim.start(stage)
			game.sim.operation.completed=1 if stage==2 else 0
			game.camera_pos=game.sim.pos
			game.mode="play"
			key(KEY_M)
			check(game.mode=="map","M opens water map")
			var before: Dictionary=game.sim.save_data().duplicate(true)
			var position: Vector2=game.sim.pos
			game._process(0.05)
			check(game.sim.save_data()==before and game.sim.pos==position,"Water encounter is paused")
			await capture("aguas-%d-%d" % [stage+1,size.x])
			game.previous_mode="prologue"
			close_click()
			check(game.mode=="play","Return click resumes gameplay")
			game.previous_mode="play"
			key(KEY_M)
			key(KEY_ESCAPE)
			check(game.mode=="play","Escape closes water map")
		game.sim.restored=4
		game.sim.operation.completed=2
		game.sim.enemies.clear()
		game.sim.wave=2
		game.sim.state="activation"
		game.mode="map"
		await capture("aguas-restaurado-%d" % size.x)
	game.free()
	game=load("res://scenes/residues.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.sound.set_muted(true)
	game.toast_time=0
	var original_enemies: Array=game.enemies.duplicate(true)
	for size in [Vector2i(960,540),Vector2i(1440,810),Vector2i(1280,720)]:
		resolution(size)
		for stage in 4:
			game.stage=stage
			game.enemies=original_enemies.duplicate(true)
			for enemy in game.enemies:
				if enemy.zone<stage: enemy.hp=0
			game.sorted=[stage>0,stage>0,stage>0,stage>0]
			game.cleared=[stage>1,stage>1,stage>2,stage>2]
			game.carried=1 if stage==0 else -1
			for i in 3: game.terminal_on[i]=i<stage
			game.pos=game.M.START if stage==0 else game.M.TERMINALS[mini(stage,2)]
			game._guide_timer=0
			game._update_guidance()
			game.state="play"
			key(KEY_M)
			check(game.state=="map","M opens residue map")
			var position: Vector2=game.pos
			var hp: int=game.hp
			var cd: float=game.secondary_cd
			game._physics_process(0.05)
			check(game.pos==position and game.hp==hp and game.secondary_cd==cd,"Residue encounter is paused")
			await capture("residuos-%d-%d" % [stage+1,size.x])
			close_click()
			check(game.state=="play" and game._map_mouse_held,"Return click is consumed by map")
			key(KEY_M)
			key(KEY_M)
			check(game.state=="play","M closes residue map")
			key(KEY_M)
			key(KEY_ESCAPE)
			check(game.state=="play","Escape closes residue map")
	game.free()
	for frame in 6: await process_frame
	print("MAP_REVIEW_%s: %d captures; %d checks; %d failures" % ["OK" if failures.is_empty() else "FAILED",captures,checks,failures.size()])
	quit(0 if failures.is_empty() else 1)