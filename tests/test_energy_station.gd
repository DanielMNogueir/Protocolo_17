extends SceneTree
## Structural and gameplay-contract checks for the modular energy station.

const W = preload("res://scripts/world.gd")
const EnergyStation = preload("res://scripts/energy_station.gd")
const STATION_SCENE = preload("res://scenes/structures/energy_station.tscn")

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _run() -> void:
	var station := STATION_SCENE.instantiate()
	station.position=EnergyStation.WORLD_ORIGIN
	root.add_child(station)
	await process_frame
	check(station is P17WorldStructure, "Energy station inherits the reusable world-structure state machine")
	check(station.y_sort_enabled, "Energy station scene enables Y sorting")
	check(station.get_node_or_null("VisualMain/ControlRoom") != null, "Control-room art is modular")
	check(station.get_node_or_null("VisualMain/Generator") != null, "Generator art is modular")
	check(station.get_node_or_null("StaticBody2D/ControlRoomFootprint") != null, "Control room has a dedicated collider")
	check(station.get_node_or_null("StaticBody2D/GeneratorFootprint") != null, "Generator has a separate collider")
	var shapes := ["ControlRoomFootprint","GeneratorFootprint","TerminalFootprint"]
	for index in range(shapes.size()):
		var shape: CollisionShape2D=station.get_node("StaticBody2D/"+shapes[index])
		var expected: Rect2=EnergyStation.COLLISION_RECTS[index]
		var actual:=Rect2(shape.global_position-shape.shape.size*0.5,shape.shape.size)
		check(actual.position.is_equal_approx(expected.position) and actual.size.is_equal_approx(expected.size),"Scene collider and gameplay footprint agree for "+shapes[index])
	check(station.get_node_or_null("Area2D_Interaction/CollisionShape2D") != null, "Terminal has an interaction area")
	check(station.get_node_or_null("NavigationObstacle2D") != null, "Station exposes a navigation obstacle")
	check(station.get_node_or_null("AnimationPlayer") != null, "Station owns an animation player")
	check(station.get_node_or_null("Effects/Particles") != null, "Station owns bounded particles")
	check(station.get_node_or_null("Effects/Light2D") != null, "Station owns local light")
	check(station.get_node_or_null("AudioStreamPlayer2D") != null, "Station owns positional-audio hook")
	check(station.get_node_or_null("InteractionIndicator") != null, "Station owns an interaction indicator")
	check(station.interaction_prompt == "[E] REPARAR SISTEMA", "Interaction prompt matches the gameplay instruction")
	check(W.GOALS[1] == EnergyStation.INTERACTION_POINT, "Energy objective uses the station terminal point")
	check(W.walkable(W.GOALS[1], 14.0, 1), "Lia can stand at the energy terminal")
	for rect in EnergyStation.COLLISION_RECTS:
		check(not W.walkable(rect.get_center(), 14.0, 1), "Every visible station footprint blocks movement")
	station.set_online(true, true)
	check(station.state_name() == &"starting", "Repair enters the startup state")
	station.advance_state(station.startup_duration + 0.01)
	check(station.state_name() == &"online" and station.is_online(), "Startup finishes in the online state")
	station.set_online(false, false)
	check(station.state_name() == &"offline", "Station can return to the offline presentation")
	station.queue_free()
	await process_frame
	print("ENERGY_STATION_TEST_%s: %d checks; %d failures" % ["OK" if failures.is_empty() else "FAILED", checks, failures.size()])
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)
