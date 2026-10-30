extends SceneTree
## Real menus, isolated from player storage, fullscreen and quitting.
class Shell extends "res://scripts/main.gd":
	var saved: Dictionary = {}
	var requested_exit := false
	func _save_checkpoint() -> void: saved=sim.save_data().duplicate(true)
	func _read_checkpoint() -> Dictionary: return saved.duplicate(true)
	func _load_settings() -> void: pass
	func _save_settings() -> void: pass
	func _toggle_fullscreen() -> void: fullscreen=not fullscreen
	func _action(id: String) -> void:
		if id=="exit": requested_exit=true; return
		super._action(id)
var game: Shell
var out := OS.get_environment("P17_MENU_OUTPUT")
var captures := 0
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label); push_error(label)
func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode=code
	event.pressed=true
	game._unhandled_input(event)
func click(id: String) -> void:
	var targets: Array=game.buttons.filter(func(button): return button.id==id)
	check(targets.size()==1,"Unique menu action: "+id)
	if targets.size()!=1: return
	var event := InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT
	event.pressed=true
	event.position=targets[0].rect.get_center()
	game._unhandled_input(event)
	game.ui_mouse_held=false
func render() -> void:
	game.queue_redraw()
	for frame in 4: await process_frame
	await RenderingServer.frame_post_draw
	var viewport := Rect2(Vector2.ZERO,game._size())
	for i in game.buttons.size():
		check(viewport.encloses(game.buttons[i].rect),"Button inside viewport: "+game.buttons[i].id)
		for j in range(i+1,game.buttons.size()):
			check(not game.buttons[i].rect.intersects(game.buttons[j].rect),"Separate click targets")
func capture(label: String) -> void:
	await render()
	check(root.get_texture().get_image().save_png(out.path_join(label+".png"))==OK,"Capture saved")
	captures+=1
func title(has_save: bool) -> void:
	game.prologue=null
	game.mode="title"
	game.has_save=has_save
	game.requested_exit=false
	game.menu_focus=""
	game.pointer=Vector2(-100,-100)
func run() -> void:
	if out.is_empty():out=ProjectSettings.globalize_path("user://menu-review")
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size=Vector2i(960,540)
	root.size=Vector2i(960,540)
	game=Shell.new()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	game.sim.start(0)
	game.sim.state="upgrade"
	game.sim.restored=1
	game.sim.choose_upgrade(0)
	game._save_checkpoint()
	for resolution in [Vector2i(960,540),Vector2i(1440,810),Vector2i(1280,720)]:
		root.content_scale_size=Vector2i(1280,720) if resolution.x==1280 else Vector2i(960,540)
		root.size=resolution
		var suffix := "-%d" % resolution.x
		title(false)
		await capture("01-inicial-sem-save"+suffix)
		check(game.buttons.size()==4,"New player has start, settings, prologue and exit")
		click("settings")
		check(game.mode=="settings" and game.settings_return=="title","Settings open from title")
		await capture("03-configuracoes"+suffix)
		var was_muted: bool=game.muted
		click("sound")
		check(game.muted!=was_muted,"Audio control works")
		await render()
		click("fullscreen")
		check(game.fullscreen,"Fullscreen control dispatches")
		await render()
		click("fullscreen")
		await render()
		click("back")
		check(game.mode=="title","Settings return to title")
		await render()
		key(KEY_UP)
		check(game.menu_focus=="exit","Keyboard wraps to exit")
		key(KEY_ENTER)
		check(game.requested_exit,"Exit action is reachable safely")
		title(false)
		await render()
		click("new")
		check(game.mode=="difficulty","Start opens difficulty")
		await capture("04-dificuldade"+suffix)
		key(KEY_ESCAPE)
		check(game.mode=="title","Escape returns from difficulty")
		title(true)
		await capture("02-inicial-com-save"+suffix)
		check(game.buttons.size()==5,"Saved game retains all five menu actions")
		key(KEY_DOWN)
		check(game.menu_focus=="continue","Keyboard selects primary action")
		key(KEY_DOWN)
		check(game.menu_focus=="new","Keyboard selects new operation")
		await capture("05-foco-teclado"+suffix)
		key(KEY_ENTER)
		check(game.mode=="difficulty","Keyboard activates focused action")
		title(true)
		await render()
		click("continue")
		check(game.mode=="play" and game.sim.stage==1,"Continue loads checkpoint")
		game.dialogue.clear()
		key(KEY_ESCAPE)
		await capture("06-pausa"+suffix)
		click("settings")
		await capture("07-configuracoes-na-pausa"+suffix)
		click("back")
		check(game.mode=="pause","Settings return to pause")
		await render()
		click("resume")
		check(game.mode=="play","Resume returns to gameplay")
		title(true)
		await render()
		click("intro_replay")
		check(game.mode=="prologue","Replay starts prologue")
		key(KEY_ESCAPE)
		await capture("08-pausa-do-prologo"+suffix)
		click("intro_skip")
		check(game.mode=="title","Skip replay returns to title")
	game.free()
	for frame in 8: await process_frame
	print("MENU_REVIEW_%s: %d captures; %d checks; %d failures; storage and fullscreen isolated" % ["OK" if failures.is_empty() else "FAILED",captures,checks,failures.size()])
	quit(0 if failures.is_empty() else 1)