extends SceneTree
## Pure rules of the Energy district: overload, mirrors, arcs, relays, battery.
const Mechanics = preload("res://scripts/power_mechanics.gd")
const Loadout = preload("res://scripts/campaign_loadout.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	_run()
	print("POWER_MECHANICS_%s: %d checks; %d failures" % ["OK" if failures == 0 else "FAILED", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

## Advances the needle until it sits inside (or outside) the current window.
func _seek(overload, inside: bool) -> bool:
	for i in 4000:
		if overload.in_window() == inside: return true
		overload.tick(1.0 / 240.0)
	return false

func _run() -> void:
	# Overload: three clean presses complete the console.
	var overload = Mechanics.Overload.new("operation")
	_check(overload.press() == "start", "first E press starts the overload sweep")
	for pulse in 3:
		_check(_seek(overload, true), "needle reaches window %d" % pulse)
		var result: String = overload.press()
		_check(result == ("done" if pulse == 2 else "hit"), "pulse %d registers inside the window" % pulse)
	_check(overload.done, "three pulses restore the system")
	# A miss discharges, resets and locks.
	overload = Mechanics.Overload.new("veteran")
	overload.press()
	_check(_seek(overload, true), "veteran window is reachable")
	overload.press()
	_check(overload.hits == 1, "first hit counted")
	_check(_seek(overload, false), "needle can leave the window")
	_check(overload.press() == "discharge", "press outside the window discharges")
	_check(overload.hits == 0 and not overload.running and overload.cooldown > 2.9, "discharge resets the sequence and locks the console")
	_check(overload.press() == "", "locked console ignores presses")
	overload.tick(3.1)
	_check(overload.available() and overload.press() == "start", "console recovers after the lockout")
	# Window shrinks, moves, and difficulty/module change the width.
	var easy = Mechanics.Overload.new("story")
	var hard = Mechanics.Overload.new("veteran")
	var steady = Mechanics.Overload.new("veteran", 1.3)
	_check(easy.window_half() > hard.window_half(), "easier difficulty has a wider window")
	_check(is_equal_approx(steady.window_half(), hard.window_half() * 1.3), "Sobrecarga controlada widens the window by 30%")
	var first_center: float = hard.window_center()
	hard.hits = 1
	_check(hard.window_center() != first_center and hard.window_half() < hard.half_width, "each hit moves and narrows the window")
	var surge = Mechanics.Overload.new("operation", 1.0, "surge")
	var speeds: Array[float] = []
	for i in 8:
		surge.tick(0.7)
		speeds.append(surge.speed())
	_check(speeds.max() - speeds.min() > 0.25 and speeds.min() > 0.0, "tower oscillation changes speed but never stops")
	overload = Mechanics.Overload.new()
	overload.press()
	overload.tick(0.4)
	overload.cancel()
	_check(not overload.running and overload.cooldown == 0.0, "walking away cancels without penalty")

	# Mirrors: relay chain lights in order and locks when solved.
	var mirrors = Mechanics.Mirrors.new()
	_check(mirrors.lit_count() == 1 and not mirrors.solved, "only the first mirror receives sunlight at start")
	_check(mirrors.rotate(1) and not mirrors.rotate(1), "a turning mirror ignores another hit")
	mirrors.tick(1.0)
	for index in 3:
		var guard := 0
		while not mirrors.aligned(index) and guard < 9:
			mirrors.rotate(index)
			mirrors.tick(1.0)
			guard += 1
		_check(mirrors.aligned(index), "mirror %d can be aligned by hits alone" % index)
		_check(mirrors.lit_count() >= index + 2, "aligned mirror %d passes the beam on" % index)
	_check(mirrors.update_solved() and mirrors.lit_count() == 4, "three aligned mirrors light the collector")
	_check(not mirrors.rotate(0), "solved mirrors are locked")
	for i in 8:
		_check(Mechanics.direction(i).is_normalized(), "direction %d is unit length" % i)
	_check(Mechanics.direction(2).is_equal_approx(Vector2.DOWN) and Mechanics.direction(6).is_equal_approx(Vector2.UP), "mirror directions are clockwise on screen")

	# Arcs: idle -> warning -> active on a fixed rhythm.
	var arc = Mechanics.ArcPair.new(Vector2(0, 0), Vector2(0, 100), 2.6, 0.0)
	_check(arc.state(0.0) == "idle" and arc.state(1.5) == "warning" and arc.state(2.2) == "active", "arc rhythm is idle, warning, active")
	_check(arc.warning_amount(1.6) > 0.0 and arc.warning_amount(1.6) < 1.0, "warning ramps up before the discharge")
	_check(arc.touches(Vector2(6, 50), 10) and not arc.touches(Vector2(30, 50), 10), "arc contact uses the segment between pylons")

	# Relays: all three must hold charge together.
	var relays = Mechanics.Relays.new("operation")
	relays.energize(0)
	relays.tick(relays.window + 0.1)
	relays.energize(1)
	relays.energize(2)
	_check(not relays.solved and relays.lit_count() == 2, "an expired relay breaks the chain")
	relays.energize(0)
	_check(relays.solved and relays.lit_count() == 3, "three charged relays solve the tower")
	relays.tick(30.0)
	_check(relays.lit_count() == 3, "a solved chain stays energized")
	_check(Mechanics.Relays.new("story").window > Mechanics.Relays.new("veteran").window, "relay window depends on difficulty")

	# Battery: charge only in the ring, venting prevents overloads.
	var battery = Mechanics.Battery.new("operation")
	var events: Array[String] = battery.tick(1.0, false)
	_check(events.is_empty() and not battery.started and battery.charge == 0.0, "battery waits for Lia in the ring")
	events = battery.tick(0.1, true)
	_check("start" in events and battery.charge > 0.0, "stepping in the ring starts charging")
	var before: float = battery.charge
	battery.tick(2.0, false)
	_check(battery.charge == before, "leaving the ring pauses the charge")
	var overloads := 0
	var waves := 0
	var guard := 0
	while not battery.done and guard < 6000:
		for event in battery.tick(1.0 / 30.0, true):
			if event.begins_with("overload"): overloads += 1
			if event.begins_with("wave"): waves += 1
		if battery.danger(battery.surging): battery.vent(battery.surging)
		guard += 1
	_check(battery.done and overloads == 0, "venting every surge completes the bank without overloads")
	_check(waves == 4, "four reinforcement waves are announced during the charge")
	battery = Mechanics.Battery.new("operation")
	battery.tick(0.1, true)
	battery.charge = 0.5
	var overloaded := false
	for i in 900:
		for event in battery.tick(1.0 / 30.0, true):
			if event.begins_with("overload"): overloaded = true
		if overloaded: break
	_check(overloaded and battery.charge < 0.5 + 30.0 / battery.duration, "an ignored surge overloads and costs charge")
	var surges: Array[int] = []
	for i in 7:
		surges.append(battery.surging)
		battery.vent(battery.surging)
	var repeated := false
	for i in range(1, surges.size()):
		if surges[i] == surges[i - 1]: repeated = true
	_check(not repeated, "the surging cell always changes after a vent")

	# Loadout: campaign module effects.
	var loadout = Loadout.new()
	loadout.configure("veteran", ["reserve_cell", "induction_coil", "water_stride", "grounded_suit"])
	_check(loadout.max_hp == 7 and loadout.pulse_damage == 2 and is_equal_approx(loadout.move_speed, 225.0) and is_equal_approx(loadout.dash_recharge, 1.05), "Water modules apply on top of difficulty")
	_check(loadout.shock_factor == 0.5 and loadout.timing_scale == 1.0 and not loadout.chain_pulse, "Isolamento halves electrical damage")
	loadout.configure("story", ["focused_pulse", "efficient_dash", "clean_frequency", "steady_hand"])
	_check(loadout.max_hp == 9 and loadout.timing_scale == 1.3 and is_equal_approx(loadout.fire_interval, 0.145 * 0.8 / 1.2), "Sobrecarga controlada and cadence modules apply")
	loadout.configure("unknown", ["conductive_pulse"])
	_check(loadout.difficulty == "operation" and loadout.chain_pulse, "invalid difficulty falls back to Médio; Pulso condutor arcs")
