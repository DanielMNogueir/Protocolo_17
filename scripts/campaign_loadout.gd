class_name P17CampaignLoadout
extends RefCounted
## Lia's campaign stats outside the Water simulation. Water base values and
## perk effects are canonical (simulation.gd); test_campaign_loadout.gd keeps
## both in agreement. Residues and Energy build their stats from this.

const Simulation = preload("res://scripts/simulation.gd")

## Fourth module set, offered after Residues and used in Energy.
const RESIDUE_UPGRADES: Array = [
	{"id": "grounded_suit", "title": "Isolamento", "description": "Descargas e arcos elétricos causam metade do dano."},
	{"id": "steady_hand", "title": "Sobrecarga controlada", "description": "Janelas de sincronização 30% mais largas."},
	{"id": "conductive_pulse", "title": "Pulso condutor", "description": "Cada acerto salta para um drone próximo."},
]

var difficulty := "operation"
var upgrades: Array = []
var max_hp := 6
var move_speed := 205.0
var fire_interval := 0.145
var pulse_speed := 640.0
var pulse_damage := 1
var dash_recharge := 1.2
var secondary_recharge := 3.8
## Fraction of electrical damage Lia receives (1.0 = full).
var shock_factor := 1.0
## Multiplier for every timing window in Energy.
var timing_scale := 1.0
## Whether a primary pulse arcs to a second drone on hit.
var chain_pulse := false


static func base_health(level: String) -> int:
	return 9 if level == "story" else (5 if level == "veteran" else 6)


static func is_residue_upgrade(id: String) -> bool:
	for option in RESIDUE_UPGRADES:
		if option.id == id: return true
	return false


func configure(level: String, chosen: Array) -> void:
	difficulty = level if level in Simulation.DIFFICULTIES else "operation"
	upgrades = chosen.duplicate()
	max_hp = base_health(difficulty)
	move_speed = 205.0
	fire_interval = 0.145
	pulse_speed = 640.0
	pulse_damage = 1
	dash_recharge = 1.2
	shock_factor = 1.0
	timing_scale = 1.0
	chain_pulse = false
	for id in upgrades: _apply(str(id))


func _apply(id: String) -> void:
	match id:
		"focused_pulse": fire_interval *= 0.8
		"reserve_cell", "reclaimed_armor", "living_circuit": max_hp += 2
		"light_harness": move_speed += 25.0
		"induction_coil": pulse_damage += 1
		"efficient_dash": dash_recharge -= 0.25
		"clean_frequency":
			fire_interval /= 1.2
			pulse_speed *= 1.15
		"water_stride":
			move_speed += 20.0
			dash_recharge -= 0.15
		"grounded_suit": shock_factor = 0.5
		"steady_hand": timing_scale = 1.3
		"conductive_pulse": chain_pulse = true
