extends SceneTree
var game: Node2D
var checks := 0
var failures := 0
const OUTPUT := "res://captures/beta_021"

func _initialize() -> void: _run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func capture(label: String) -> void:
	game.pointer = Vector2(-100,-100)
	game.toast_time=0
	game.screen_flash=0
	game.shake=0
	game._clamp_camera()
	game._update_energy_station(2.0)
	for frame in 5:
		game.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(not image.is_empty(),"Rendered viewport: "+label)
	check(image.save_png(OUTPUT+"/"+label+".png")==OK,"Saved capture: "+label)
	for button in game.buttons:
		check(Rect2(Vector2.ZERO,game._size()).encloses(button.rect),"Button fits viewport: "+button.id)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.content_scale_size=Vector2i(960,540)
	root.size=Vector2i(960,540)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	game.clock=12
	game._action("new")
	check(game.mode=="difficulty","New operation opens difficulty selection")
	await capture("01_dificuldade_960")
	game._action("difficulty_veteran")
	check(game.mode=="prologue","Difficulty starts original prologue")
	game._action("intro_skip")
	check(game.sim.difficulty=="veteran" and game.mode=="play","Difficulty survives prologue handoff")
	game.sim.start()
	game.camera_pos=game.sim.pos+Vector2(130,-95)
	await capture("02_captacao_960")
	game.sim.pos=Vector2(740,1450)
	game.sim.tick(0.05,Vector2.ZERO,Vector2(960,1410),true,false,false,0,false,true)
	game.camera_pos=game.sim.pos
	await capture("03_disparos_960")
	game.sim.start()
	game.sim.state="upgrade"
	game.sim.restored=1
	game.mode="upgrade"
	await capture("03_melhorias_960")
	game.mode="play"
	for stage in 4:
		game.sim.start(stage)
		game.sim.enemies.clear()
		game.sim.tick(0.001,Vector2.ZERO,game.sim.pos+Vector2.UP,false,false,false)
		if stage==2: game.sim.operation.completed=1
		game.sim.pos=game.sim.operation.target()
		game.sim.operation.clock=0.84
		game.camera_pos=game.sim.pos
		await capture("04_operacao_%d_960" % stage)
		if stage==1:
			game.sim.operation.completed=1
			game.sim.pos=game.sim.operation.target()
			game.camera_pos=game.sim.pos
			await capture("04_bateria_visivel_960")
	game.mode="map"
	await capture("05_mapa_960")
	game.mode="play"
	game.sim.start(3)
	game.sim.operation.completed=2
	game.sim.enemies.clear()
	game.sim.wave=2
	game.sim._spawn_reinforcements()
	game.sim.pos=Vector2(2110,1250)
	game.camera_pos=Vector2(2110,1350)
	for enemy in game.sim.enemies:
		if enemy.kind=="boss":
			enemy.hp=24
			enemy.tier=2
			enemy.warning=0.65
			game.sim._enemy_attack(enemy)
	game.enemy_presentation.reset()
	game.enemy_presentation.advance(0.016,game.sim.enemies,3,12)
	await capture("06_guardiao_960")
	game.sim.state="victory"
	game.sim.restored=4
	game.sim.elapsed=134.8167
	game.sim.kills=57
	game.mode="victory"
	await capture("07_vitoria_960")
	root.size=Vector2i(1440,810)
	game.mode="play"
	game.sim.start(2)
	game.sim.enemies.clear()
	game.sim.state="activation"
	game.sim.operation.completed=1
	game.sim.pos=game.sim.operation.target()
	game.camera_pos=game.sim.pos
	await capture("08_tratamento_1440")
	game.mode="difficulty"
	await capture("09_dificuldade_1440")
	game.free()
	for frame in 5: await process_frame
	print("BETA_RENDER_%s: %d checks; %d failures" % ["OK" if failures==0 else "FAILED",checks,failures])
	quit(0 if failures==0 else 1)
