class_name P17PowerMechanics
extends RefCounted
## Deterministic rules for the Energy district. No drawing, no scene access:
## power_scenario.gd feeds time, presses and hits; tests drive them directly.

const DIFFICULTY_INDEX := {"story": 0, "operation": 1, "veteran": 2}

## Directions used by mirrors: index * 45°, clockwise on screen (y down).
static func direction(index: int) -> Vector2:
	return Vector2.RIGHT.rotated(posmod(index, 8) * PI / 4.0)


## Sobrecarga v2: three presses in a moving, narrowing window. A press outside
## the window discharges, resets the sequence and locks the console.
class Overload:
	const CENTERS := [0.5, 0.28, 0.71]
	const BASE_HALF := [0.17, 0.125, 0.09]
	const LOCKOUT := 3.0
	var pulses := 3
	var hits := 0
	var running := false
	var done := false
	var cooldown := 0.0
	var phase := 0.0
	var clock := 0.0
	var half_width := 0.125
	## "steady" sweeps at a constant rate; "surge" follows a grid oscillation
	## whose speed changes over time (Torre Norte).
	var pattern := "steady"
	var flash := 0.0

	func _init(level: String = "operation", timing_scale: float = 1.0, mode: String = "steady") -> void:
		half_width = BASE_HALF[DIFFICULTY_INDEX.get(level, 1)] * timing_scale
		pattern = mode

	func speed() -> float:
		if pattern == "surge": return 0.5 + 0.32 * sin(clock * 1.35) + 0.12 * sin(clock * 3.1)
		return 0.62

	func needle() -> float:
		return pingpong(phase, 1.0)

	func window_center() -> float:
		return CENTERS[mini(hits, CENTERS.size() - 1)]

	func window_half() -> float:
		return half_width * pow(0.82, hits)

	func in_window() -> bool:
		return absf(needle() - window_center()) <= window_half()

	func tick(dt: float) -> void:
		clock += dt
		flash = maxf(0.0, flash - dt)
		if cooldown > 0.0:
			cooldown = maxf(0.0, cooldown - dt)
			return
		if running and not done: phase += dt * speed()

	func available() -> bool:
		return not done and cooldown <= 0.0

	## Returns "start", "hit", "done", "discharge" or "" (ignored press).
	func press() -> String:
		if done or cooldown > 0.0: return ""
		if not running:
			running = true
			phase = 0.0
			return "start"
		if in_window():
			hits += 1
			flash = 0.25
			if hits >= pulses:
				done = true
				running = false
				return "done"
			return "hit"
		hits = 0
		running = false
		cooldown = LOCKOUT
		return "discharge"

	## Walking away abandons the sequence without a penalty.
	func cancel() -> void:
		if done: return
		running = false
		hits = 0


## Three heliostat mirrors relay a sunbeam to the collector. Each hit turns a
## mirror 45° clockwise. A mirror only receives light when the previous link
## points at it.
class Mirrors:
	const TARGET := [2, 4, 6]
	const START := [0, 1, 3]
	const TURN_TIME := 0.32
	var orientation: Array[int] = []
	var turning: Array[float] = [0.0, 0.0, 0.0]
	var solved := false

	func _init() -> void:
		orientation.assign(START)

	func tick(dt: float) -> void:
		for i in 3: turning[i] = maxf(0.0, turning[i] - dt)

	func aligned(index: int) -> bool:
		return orientation[index] == TARGET[index]

	## Number of mirrors receiving the beam (1..3); 4 means the collector is lit.
	func lit_count() -> int:
		var count := 1
		for i in 3:
			if not aligned(i) or turning[i] > 0.0: return count
			count += 1
		return count

	func rotate(index: int) -> bool:
		if solved or index < 0 or index > 2 or turning[index] > 0.0: return false
		orientation[index] = (orientation[index] + 1) % 8
		turning[index] = TURN_TIME
		return true

	## Call after ticking; locks the puzzle once the collector receives light.
	func update_solved() -> bool:
		if not solved and lit_count() == 4: solved = true
		return solved


## Arc pylons fire on a fixed rhythm with a visible warning beforehand.
class ArcPair:
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var period := 2.6
	var active_time := 0.7
	var warn_time := 0.6
	var offset := 0.0

	func _init(from: Vector2, to: Vector2, rhythm: float, shift: float, active: float = 0.7, warn: float = 0.6) -> void:
		a = from
		b = to
		period = rhythm
		offset = shift
		active_time = active
		warn_time = warn

	## "idle", "warning" or "active".
	func state(time: float) -> String:
		var phase := fposmod(time + offset, period)
		if phase >= period - active_time: return "active"
		if phase >= period - active_time - warn_time: return "warning"
		return "idle"

	func warning_amount(time: float) -> float:
		var phase := fposmod(time + offset, period)
		var start := period - active_time - warn_time
		return clampf((phase - start) / warn_time, 0.0, 1.0) if state(time) == "warning" else 0.0

	func touches(point: Vector2, radius: float) -> bool:
		return point.distance_to(Geometry2D.get_closest_point_to_segment(point, a, b)) < radius


## Three relays must hold charge at the same time. A pulse charges one relay
## for a limited window.
class Relays:
	const WINDOW := [9.0, 7.0, 5.5]
	var window := 7.0
	var charge: Array[float] = [0.0, 0.0, 0.0]
	var solved := false

	func _init(level: String = "operation", timing_scale: float = 1.0) -> void:
		window = WINDOW[DIFFICULTY_INDEX.get(level, 1)] * timing_scale

	func tick(dt: float) -> void:
		if solved: return
		for i in 3: charge[i] = maxf(0.0, charge[i] - dt)

	func energize(index: int) -> bool:
		if solved or index < 0 or index > 2: return false
		charge[index] = window
		if charge.min() > 0.0: solved = true
		return true

	func lit(index: int) -> bool:
		return solved or charge[index] > 0.0

	func lit_count() -> int:
		var count := 0
		for i in 3:
			if lit(i): count += 1
		return count


## Banco de Baterias: charge rises only while Lia stands in the ring. One cell
## at a time surges; venting it at its console keeps the bank stable. A cell
## that reaches the top discharges and costs charge.
class Battery:
	const DURATION := [30.0, 36.0, 42.0]
	const SURGE := [0.085, 0.12, 0.155]
	const WAVES := [0.15, 0.4, 0.65, 0.85]
	var duration := 36.0
	var surge_rate := 0.12
	var charge := 0.0
	var started := false
	var done := false
	var cells: Array[float] = [0.42, 0.5, 0.46]
	var surging := 0
	var surge_delay := 2.5
	var waves_sent := 0
	var _sequence := 0

	func _init(level: String = "operation", timing_scale: float = 1.0) -> void:
		var index: int = DIFFICULTY_INDEX.get(level, 1)
		duration = DURATION[index]
		surge_rate = SURGE[index] / timing_scale

	## Returns events: "start", "overload:<cell>", "wave:<n>", "done".
	func tick(dt: float, inside_ring: bool) -> Array[String]:
		var events: Array[String] = []
		if done: return events
		if not started:
			if not inside_ring: return events
			started = true
			events.append("start")
		if inside_ring: charge = minf(1.0, charge + dt / duration)
		while waves_sent < WAVES.size() and charge >= WAVES[waves_sent]:
			events.append("wave:%d" % waves_sent)
			waves_sent += 1
		if charge >= 1.0:
			done = true
			events.append("done")
			return events
		for i in 3:
			if i == surging and surge_delay <= 0.0: cells[i] = minf(1.0, cells[i] + surge_rate * dt)
			else: cells[i] = move_toward(cells[i], 0.48, 0.05 * dt)
		surge_delay = maxf(0.0, surge_delay - dt)
		if cells[surging] >= 1.0:
			events.append("overload:%d" % surging)
			charge = maxf(0.0, charge - 0.1)
			cells[surging] = 0.55
			_next_surge()
		return events

	func vent(index: int) -> bool:
		if not started or done or index < 0 or index > 2: return false
		cells[index] = maxf(0.18, cells[index] - 0.45)
		if index == surging: _next_surge()
		return true

	func danger(index: int) -> bool:
		return cells[index] >= 0.78

	func _next_surge() -> void:
		_sequence += 1
		# A fixed, readable rotation that never repeats the same cell twice.
		surging = [1, 2, 0, 2, 1, 0][_sequence % 6]
		surge_delay = 1.6
