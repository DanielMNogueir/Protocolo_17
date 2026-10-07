class_name P17WorldStructure
extends Node2D
## Small shared state machine for reusable interactive world structures.
## Gameplay-specific rules remain in the simulation that already owns them.

signal structure_state_changed(structure_id: StringName, state_name: StringName)

enum StructureState { OFFLINE, STARTING, ONLINE }

@export var structure_id: StringName = &"world_structure"
@export var interaction_prompt := "[E] REPARAR SISTEMA"
@export_range(0.1, 10.0, 0.1) var startup_duration := 1.25
@export_range(16.0, 256.0, 1.0) var interaction_radius := 84.0

var structure_state: StructureState = StructureState.OFFLINE
var state_time := 0.0


func _ready() -> void:
	_apply_scene_state()


func set_online(value: bool, animate: bool = true) -> void:
	var next_state := StructureState.ONLINE if value else StructureState.OFFLINE
	if value and animate and structure_state == StructureState.OFFLINE:
		next_state = StructureState.STARTING
	_set_state(next_state)


func advance_state(delta: float) -> void:
	state_time += maxf(delta, 0.0)
	if structure_state == StructureState.STARTING and state_time >= startup_duration:
		_set_state(StructureState.ONLINE)
	elif structure_state != StructureState.OFFLINE:
		_apply_scene_state()


func is_online() -> bool:
	return structure_state == StructureState.ONLINE


func state_name() -> StringName:
	return [&"offline", &"starting", &"online"][structure_state]


func startup_progress() -> float:
	if structure_state == StructureState.ONLINE:
		return 1.0
	if structure_state == StructureState.OFFLINE:
		return 0.0
	return clampf(state_time / maxf(startup_duration, 0.001), 0.0, 1.0)


func _set_state(next_state: StructureState) -> void:
	if structure_state == next_state:
		_apply_scene_state()
		return
	structure_state = next_state
	state_time = 0.0
	_apply_scene_state()
	structure_state_changed.emit(structure_id, state_name())


func _apply_scene_state() -> void:
	var control_panel := get_node_or_null("VisualMain/Terminal")
	if control_panel:
		control_panel.online = structure_state == StructureState.ONLINE
		control_panel.repair = startup_progress() if structure_state == StructureState.STARTING else 0.0
	var online_overlay := get_node_or_null("VisualUpper/OnlineOverlay") as CanvasItem
	if online_overlay:
		online_overlay.visible = structure_state != StructureState.OFFLINE
		var glow := 0.65 + 0.25 * sin(state_time * 5.0)
		online_overlay.modulate.a = glow if structure_state == StructureState.ONLINE else startup_progress()
	var offline_overlay := get_node_or_null("VisualUpper/OfflineOverlay") as CanvasItem
	if offline_overlay:
		offline_overlay.visible = structure_state == StructureState.OFFLINE
	var particles := get_node_or_null("Effects/Particles") as CPUParticles2D
	if particles:
		particles.emitting = structure_state != StructureState.OFFLINE
	var light := get_node_or_null("Effects/Light2D") as PointLight2D
	if light:
		light.enabled = structure_state != StructureState.OFFLINE
		light.energy = 0.45 + 0.20 * sin(state_time * 3.0) if structure_state == StructureState.ONLINE else startup_progress() * 0.35
	var animation_player := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player and animation_player.has_animation(state_name()):
		animation_player.play(state_name())
