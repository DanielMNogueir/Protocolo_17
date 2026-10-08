extends SceneTree
## Exercises the actual shell/input handlers with an in-memory save sink.
class Shell extends "res://scripts/main.gd":
	var saved: Dictionary = {}
	var writes := 0
	var setting_writes := 0
	func _save_checkpoint() -> void:
		saved = sim.save_data().duplicate(true)
		writes += 1
	func _read_checkpoint() -> Dictionary: return saved.duplicate(true)
	func _clear_checkpoint() -> void: saved.clear()
	func _load_settings() -> void: pass
	func _save_settings() -> void: setting_writes += 1

var checks := 0
var failures: Array[String] = []
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func key(shell: Shell, code: Key) -> void:
	var input := InputEventKey.new()
	input.physical_keycode = code
	input.pressed = true
	shell._unhandled_input(input)
func _run() -> void:
	var shell := Shell.new()
	root.add_child(shell)
	await process_frame
	shell.set_process(false)
	shell.sound.set_muted(true)
	shell.sim.start(2)
	shell._save_checkpoint()
	var initial := shell.saved.duplicate(true)
	var initial_writes := shell.writes
	shell._action("intro_replay")
	check(shell.mode=="prologue" and shell.prologue.phase=="context","Replay opens full world introduction")
	check(shell.saved==initial and shell.writes==initial_writes,"Opening replay preserves the campaign checkpoint")
	key(shell,KEY_TAB)
	check(shell.prologue.fast_text and shell.instant_prologue_text and shell.setting_writes==1,"Instant speech toggle updates and persists the preference")
	key(shell,KEY_ESCAPE)
	check(shell.mode=="pause" and shell.previous_mode=="prologue","Escape pauses the introduction")
	var before := shell.prologue.elapsed
	shell._process(0.05)
	check(shell.prologue.elapsed==before,"Pausing freezes playable introduction time")
	shell._action("settings")
	shell._action("back")
	check(shell.mode=="pause" and shell.previous_mode=="prologue","Settings return to the paused introduction")
	shell._action("resume")
	check(shell.mode=="prologue","Resume restores the introduction, not Lia's campaign")
	shell.prologue.phase = "lab"
	shell.prologue.step = 5
	key(shell,KEY_SHIFT)
	check(not shell.dash_requested,"Shift does not queue a dash during the prologue")
	shell.prologue.step = 1
	shell.prologue.pos = shell.Prologue.Lab.CALIBRATION
	key(shell,KEY_E)
	var released := InputEventKey.new()
	released.physical_keycode = KEY_E
	released.pressed = false
	shell._unhandled_input(released)
	shell._process(1.0/60)
	check(shell.prologue.interaction_active and not shell.prologue_interact_requested,"A press and release between frames still starts the interaction once")
	for frame in range(100): shell._process(1.0/60)
	check(shell.prologue.step==2,"The shell completes calibration without holding E")
	shell.prologue.conversation.clear()
	shell.prologue.pos = shell.Prologue.Lab.ANALYSIS
	key(shell,KEY_E)
	key(shell,KEY_ESCAPE)
	shell._action("resume")
	shell._process(1.0/60)
	check(not shell.prologue.interaction_active,"Pausing discards an unconsumed E press")
	key(shell,KEY_P)
	check(shell.mode=="title" and shell.saved==initial and shell.writes==initial_writes,"Skipping a replay returns to the title without replacing progress")
	for phase in ["context","lab","retry","ending","handoff"]:
		shell._action("new")
		shell.prologue.phase = phase
		shell.prologue.hp = 1
		shell.prologue.pos = shell.Prologue.Lab.ARCHIVE
		shell.prologue.bolts.append({"pos":Vector2.ZERO,"vel":Vector2.ONE,"life":1,"hostile":true})
		shell.dash_requested = true
		key(shell,KEY_P)
		check(shell.mode=="play" and shell.prologue==null,"P skips the entire introduction from "+phase)
		check(shell.sim.stage==0 and shell.sim.restored==0 and shell.sim.hp==shell.sim.max_hp,"Lia starts fresh after skipping "+phase)
		check(shell.sim.pos==shell.World.START and shell.sim.bullets.is_empty() and not shell.dash_requested,"No scientist state or queued attack enters the campaign")
	shell._action("new")
	shell.prologue.phase = "lab"
	key(shell,KEY_ESCAPE)
	shell._action("intro_skip")
	check(shell.mode=="play" and shell.prologue==null,"Skip button also works from the pause menu")
	shell._action("new")
	shell.prologue.phase = "handoff"
	shell.prologue.finished = true
	shell._process(0.01)
	check(shell.mode=="play" and shell.sim.stage==0,"Normal tutorial completion enters Lia's campaign")
	shell._action("intro_replay")
	shell.prologue.finished = true
	var preserved := shell.saved.duplicate(true)
	shell._process(0.01)
	check(shell.mode=="title" and shell.saved==preserved,"Normal replay completion preserves progress")
	print("PROLOGUE_SHELL_%s: %d checks; %d failures" % ["OK" if failures.is_empty() else "FAILED",checks,failures.size()])
	for failure in failures: push_error(failure)
	shell.prologue = null
	shell.free()
	shell = null
	for cleanup in range(8): await process_frame
	quit(0 if failures.is_empty() else 1)
