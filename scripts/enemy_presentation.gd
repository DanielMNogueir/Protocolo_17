extends RefCounted
## Observes combat; owns only animation, transient wrecks and sound cues.
var units: Dictionary = {}
var wrecks: Array[Dictionary] = []
var cues: Array[Dictionary] = []
var _stage := -1
var _elapsed := -1.0

func reset() -> void:
	units.clear()
	wrecks.clear()
	cues.clear()
	_stage = -1
	_elapsed = -1.0

func advance(dt: float, enemies: Array[Dictionary], stage: int, elapsed: float) -> void:
	if dt <= 0.0:
		return
	if stage != _stage or elapsed < _elapsed:
		reset()
	_stage = stage
	_elapsed = elapsed
	cues.clear()
	for i in range(wrecks.size() - 1, -1, -1):
		wrecks[i].death_age += dt
		if wrecks[i].death_age > 1.05:
			wrecks.remove_at(i)
	var alive := {}
	for enemy in enemies:
		var id: int = enemy.id
		alive[id] = true
		var fresh := not units.has(id)
		var old: Dictionary = units.get(id, enemy)
		var view: Dictionary = enemy.duplicate(true)
		var motion: Vector2 = Vector2(enemy.pos) - Vector2(old.pos)
		view["anim_time"] = float(old.get("anim_time", id * .137)) + dt
		view["moving"] = motion.length_squared() > .01
		view["facing"] = old.get("facing", enemy.aim)
		if enemy.phase in ["windup", "charge"]:
			view.facing = enemy.aim
		elif motion.length_squared() > .01:
			view.facing = motion.normalized()
		view["attack_age"] = float(old.get("attack_age", 99.0)) + dt
		if not fresh:
			if enemy.engaged and not old.engaged:
				_cue(view, "wake")
			if enemy.phase == "windup" and old.phase != "windup":
				_cue(view, "windup")
			if old.phase == "windup" and enemy.phase != "windup":
				view.attack_age = 0.0
				view.facing = enemy.aim
				_cue(view, "fire")
			if int(enemy.hp) < int(old.hp):
				_cue(view, "hit")
		units[id] = view
	for id in units.keys():
		if not alive.has(id):
			var wreck: Dictionary = units[id].duplicate(true)
			wreck["death_age"] = 0.0
			wrecks.append(wreck)
			_cue(wreck, "death")
			units.erase(id)

func _cue(view: Dictionary, event: String) -> void:
	cues.append({"id": "unit_" + str(view.kind) + "_" + event, "pos": view.pos})

func view_for(enemy: Dictionary) -> Dictionary:
	return units.get(int(enemy.id), enemy)
