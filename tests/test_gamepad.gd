extends SceneTree

const Pad = preload("res://scripts/gamepad.gd")
var failures := 0
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)


func button(index: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func tap(index: JoyButton) -> void:
	button(index, true)
	button(index, false)


func axis(index: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = index
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func frames() -> void:
	await process_frame
	await process_frame


func _run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await frames()
	var water := current_scene
	check(water.mode == "title", "The game starts at the title screen")
	tap(JOY_BUTTON_A)
	await frames()
	check(water.mode == "districts", "A opens district selection")
	tap(JOY_BUTTON_A)
	await frames()
	check(water.mode == "difficulty", "A selects Water")
	tap(JOY_BUTTON_DPAD_RIGHT)
	tap(JOY_BUTTON_A)
	await frames()
	check(water.selected_difficulty == "operation" and water.mode == "prologue", "D-pad and A select the second difficulty")
	tap(JOY_BUTTON_START)
	await frames()
	check(water.mode == "pause", "Menu opens prologue pause")
	tap(JOY_BUTTON_DPAD_UP)
	tap(JOY_BUTTON_A)
	await frames()
	check(water.mode == "play", "The prologue can be skipped from the controller pause menu")

	water.dialogue.clear()
	water.set_process(false)
	water.sim.start(3)
	var from: Vector2 = water.sim.pos
	axis(JOY_AXIS_LEFT_X, 0.12)
	check(water.gamepad.movement(water._key).is_zero_approx(), "Left stick dead zone filters drift")
	axis(JOY_AXIS_LEFT_X, 0.9)
	axis(JOY_AXIS_RIGHT_Y, -0.9)
	axis(JOY_AXIS_TRIGGER_RIGHT, 0.9)
	check(water.gamepad.firing(), "RT holds fire")
	water._process(0.03)
	check(water.sim.pos.x > from.x and water.sim.aim.dot(Vector2.UP) > 0.95, "The sticks move and aim independently")
	check(water.sim._fire_cd > 0, "RT fires through the Water gameplay loop")
	axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	tap(JOY_BUTTON_LEFT_SHOULDER)
	tap(JOY_BUTTON_RIGHT_SHOULDER)
	check(water.dash_requested and water.secondary_requested, "LB and RB queue the combat actions")
	tap(JOY_BUTTON_BACK)
	check(water.mode == "map" and not water.dash_requested and not water.secondary_requested, "View opens map and drops queued attacks")
	tap(JOY_BUTTON_A)
	check(water.mode == "play", "A closes the map")
	water._update_objective_guides(0.016)
	check(not water.water_guide.mark_destination, "A combat target never receives an objective label or diamond")
	water.sim.enemies.clear()
	water.sim.state = "activation"
	water._update_objective_guides(0.016)
	check(water.water_guide.mark_destination, "Guide markers return for field tasks")
	axis(JOY_AXIS_LEFT_X, 0.0)
	axis(JOY_AXIS_RIGHT_Y, 0.0)

	for district in ["residues", "power", "core"]:
		change_scene_to_file("res://scenes/%s.tscn" % district)
		await frames()
		var scene := current_scene
		scene.set_physics_process(false)
		if district == "core":
			scene.state = "arena"
		else:
			scene.state = "play"
		await frames()
		tap(JOY_BUTTON_BACK)
		check(scene.state == "map", "View opens the map in " + district)
		tap(JOY_BUTTON_A)
		check(scene.state == ("arena" if district == "core" else "play"), "A closes the map in " + district)
		tap(JOY_BUTTON_START)
		await frames()
		check(scene.state == "pause", "Menu pauses " + district)
		tap(JOY_BUTTON_START)
		tap(JOY_BUTTON_A)
		check(scene._interact_requested, "A quick tap reaches gameplay in " + district)
		tap(JOY_BUTTON_RIGHT_SHOULDER)
		check(scene._burst_requested if district == "core" else scene.secondary_requested, "RB queues a burst in " + district)

	var key := InputEventKey.new()
	key.physical_keycode = KEY_M
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	check(not Pad.active and current_scene.state == "map", "Keyboard input takes over from gamepad")
	print("GAMEPAD_%s: %d checks, %d failures" % ["OK" if failures == 0 else "FAILED", checks, failures])
	quit(0 if failures == 0 else 1)
