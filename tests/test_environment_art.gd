extends SceneTree
## Contract checks for the detailed environment-art integration.

const World = preload("res://scripts/world.gd")
const Bridge = preload("res://scripts/bridge_layout.gd")
const Props = preload("res://scripts/environment_props.gd")

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	check(ResourceLoader.exists("res://assets/environment/props/industrial_props_atlas.png"), "Industrial prop atlas is importable")
	check(Props.CROPS.size() == 8, "Prop atlas exposes eight isolated cells")
	var prop_size := Props.ATLAS.get_size()
	for crop in Props.CROPS:
		check(Rect2(Vector2.ZERO, prop_size).encloses(crop), "Tight prop crop stays inside its atlas")
		check(crop.size.x < 440 and crop.size.y < 410, "Prop crop removes transparent cell margins")
	for kind in ["crate", "open_crate", "stacked_crates", "barrel", "pallet", "cabinet", "barrier", "spool"]:
		check(Props.supports(kind), "Detailed art exists for %s" % kind)
	for bridge in World.BRIDGES:
		var d := Bridge.deck(bridge)
		check(minf(d.size.x,d.size.y)>=92,"Modular bridge leaves the 92px walking lane")
		check(Bridge.collision_rects(bridge).size()==2,"Solid bridge shoulders remain outside the deck")
		for part in Bridge.parts(bridge):
			if part.support:
				var base:=Rect2(part.rect.position.x,part.rect.end.y-12,part.rect.size.x,12)
				var covered:=false
				for shoulder in Bridge.collision_rects(bridge):
					if shoulder.encloses(base): covered=true
				check(covered,"Every complete pillar stands on a blocked structural shoulder")
	check(World.building_objects().size() == 6, "Six machines expose independent placements")
	for building in World.building_objects():
		check(building.visual_bounds.encloses(building.collision_rect), "Local footprint belongs to its visible equipment")
	check(World.walkable(Vector2(300, 250), 14.0, 3), "Transparent upper structure area is no longer a giant solid rectangle")
	var sortable := World.sortable_objects(Rect2(Vector2.ZERO, World.SIZE))
	var building_count := 0
	var prop_count := 0
	for object in sortable:
		if object.type == "machine":
			building_count += 1
		elif object.type == "prop":
			prop_count += 1
	check(building_count == World.building_objects().size()+1, "Every machine and the clarifier participates independently in Y sorting")
	check(prop_count >= 20, "Detailed props participate in Y sorting")
	if failures.is_empty():
		print("ENVIRONMENT_ART_TEST_OK: %d checks; detailed props, bridges, local footprints and Y sorting verified" % checks)
	else:
		print("ENVIRONMENT_ART_TEST_FAILED: %d failures / %d checks: %s" % [failures.size(), checks, str(failures)])
	quit(0 if failures.is_empty() else 1)
