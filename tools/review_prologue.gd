extends SceneTree
const Intro = preload("res://scripts/prologue.gd")
var game: Node2D
var output := "res://captures/prologo"

func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	if not OS.get_environment("P17_PROLOGUE_OUTPUT").is_empty(): output = OS.get_environment("P17_PROLOGUE_OUTPUT")
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_size = Vector2i(960,540)
	root.size = Vector2i(1440,810)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	game._start_prologue(true)
	game.prologue.fast_text = true
	await _capture("01_mundo")
	var cases := [
		["02_rotina",1,Intro.Lab.START,Intro.Lab.SIZE/2,[]],
		["03_resposta",2,Intro.Lab.ANALYSIS,Intro.Lab.SIZE/2,[["beatrix","Circuito estável. Agora, mostre a análise ambiental."]]],
		["04_ruptura",3,Intro.Lab.RELAY_APPROACH,Intro.Lab.SIZE/2,[["system","Solicitação negada. Iniciando contenção da intervenção humana."]]],
		["04_atuador",3,Intro.Lab.START,Intro.Lab.SIZE/2,[]],
		["05_fuga",5,Intro.Lab.ESCAPE,Intro.Lab.SIZE/2,[]],
		["06_registro",6,Intro.Lab.ARCHIVE,Intro.Lab.SIZE/2,[]],
	]
	for c in cases:
		var story := Intro.new()
		story.phase = "lab"
		story.step = c[1]
		story.pos = c[2]
		story.elapsed = 12
		story.fast_text = true
		story.conversation = c[4].duplicate(true)
		story.dialogue_blocks = story.step==3
		story.threat_age = 3
		game.prologue = story
		game.prologue_camera = Intro.Lab.camera(c[3],Vector2(960,540))
		await _capture(c[0])
	game.previous_mode = "prologue"
	game.mode = "pause"
	await _capture("07_pausa")
	game.mode = "prologue"
	game.prologue.phase = "ending"
	game.prologue.cut_age = 4
	await _capture("08_registro_preservado")
	game.prologue.phase = "handoff"
	await _capture("09_lia")
	root.content_scale_size = Vector2i(960,640)
	root.size = Vector2i(1440,960)
	game.prologue = Intro.new()
	game.prologue.phase = "lab"
	game.prologue.step = 1
	game.prologue.elapsed = 12
	game.prologue_camera = Intro.Lab.SIZE/2
	await _capture("10_laboratorio")
	for player in game.sound.get_children():
		if player is AudioStreamPlayer:
			player.stop()
			player.stream = null
	for cleanup in range(3): await process_frame
	game.free()
	game = null
	for cleanup in range(5): await process_frame
	print("PROLOGUE_REVIEW_OK: 11 actual game views")
	quit(0)

func _capture(label: String) -> void:
	for frame in range(5):
		game.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output+"/"+label+".png")!=OK:
		push_error("Could not save prologue capture")
		quit(1)
