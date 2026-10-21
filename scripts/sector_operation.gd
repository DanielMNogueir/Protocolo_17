class_name P17SectorOperation
extends RefCounted
## Tasks belong to the current attempt. Completed sectors remain in simulation.
const W = preload("res://scripts/world.gd")
const LABELS := [
	["DESOBSTRUIR A GRADE", "ABRIR A ADMISSÃO"],
	["SINCRONIZAR O GERADOR", "CONECTAR A BATERIA"],
	["COLETAR AMOSTRA", "LAVAR O FILTRO"],
	["ABRIR A REDE NORTE", "ABRIR A REDE SUL"],
]
const POINTS := [
	[Vector2(660,1490), Vector2(800,1110)],
	[Vector2(670,660), Vector2(940,480)],
	[Vector2(1740,560), Vector2(2240,480)],
	[Vector2(1960,1170), Vector2(2190,1530)],
]
var stage := 0
var completed := 0
var progress := 0.0
var clock := 0.0
var cooldown := 0.0
var treatment_selected := false
var treatment_errors := 0
var _held := false
var points: Array[Vector2] = []

func reset(index: int) -> void:
	stage = index
	completed = 0
	progress = 0.0
	clock = 0.0
	cooldown = 0.0
	treatment_selected = false
	treatment_errors = 0
	_held = false
	points.clear()
	for candidate in POINTS[stage]:
		points.append(_safe_point(candidate))

func _safe_point(candidate: Vector2) -> Vector2:
	# A service point never adds collision or blocks an existing route.
	for ring in range(0, 13):
		for y in range(-ring, ring + 1):
			for x in range(-ring, ring + 1):
				var point := candidate + Vector2(x,y) * 10.0
				if W.walkable(point, 24.0, stage): return point
	return W.CHECKPOINTS[stage]

func ready() -> bool:
	return completed >= 2

func release_interaction() -> void:
	_held = false

func target() -> Vector2:
	return points[mini(completed, 1)]

func label() -> String:
	return str(LABELS[stage][mini(completed, 1)])

func charge() -> float:
	return pingpong(clock * 0.55, 1.0)

func in_window(difficulty: String) -> bool:
	var width: float = 0.22 if difficulty == "story" else (0.11 if difficulty == "veteran" else 0.16)
	return absf(charge() - 0.5) <= width

func wants_treatment(pos: Vector2) -> bool:
	return stage == 2 and completed == 1 and not treatment_selected and pos.distance_to(target()) < 72.0

func choose_treatment(index: int, pos: Vector2) -> bool:
	if not wants_treatment(pos) or cooldown > 0.0: return false
	# Sample explicitly reports suspended solids. Filtration is the correct step.
	if index != 1:
		treatment_errors += 1
		cooldown = 1.2
		return false
	treatment_selected = true
	return true

func tick(dt: float, pos: Vector2, interacting: bool, safe: bool, difficulty: String) -> String:
	clock += dt
	cooldown = maxf(0.0, cooldown-dt)
	var pressed := interacting and not _held
	_held = interacting
	if ready() or not safe or pos.distance_to(target()) > 72.0 or cooldown > 0.0:
		progress = 0.0
		return ""
	if wants_treatment(pos): return ""
	if stage == 1:
		if not pressed: return ""
		if not in_window(difficulty):
			cooldown = 0.75
			return "timing_miss"
		progress = 1.0
	elif interacting:
		progress = minf(1.0, progress + dt / (1.6 if stage == 0 else 1.2))
	else:
		progress = 0.0
	if progress < 1.0: return ""
	completed += 1
	progress = 0.0
	return "operation_done"
