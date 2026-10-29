extends SceneTree
## Pixel comparison of the actual Residues draw call against Water's shared draw.
const Actors = preload("res://scripts/actors_art.gd")
var failures := 0

class ResidueActor extends "res://scripts/residue_scenario.gd":
	func _ready() -> void: set_physics_process(false)
	func _draw() -> void: _draw_lia()

class WaterActor extends Node2D:
	var age := -1.0
	var phase := 0.0
	var walking := false
	var heading := Vector2.RIGHT
	func _draw() -> void:
		Actors.draw_lia(self, Vector2(80, 100), heading, phase, walking, false, false, "fire" if age >= 0 else "idle", age)

func _initialize() -> void: _run.call_deferred()

func _viewport() -> SubViewport:
	var view := SubViewport.new()
	view.size = Vector2i(160, 160)
	view.transparent_bg = true
	view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	return view

func _run() -> void:
	var actual := _viewport()
	var expected := _viewport()
	var residue := ResidueActor.new()
	var water := WaterActor.new()
	actual.add_child(residue)
	expected.add_child(water)
	residue.pos = Vector2(80, 100)
	var compared := 0
	for moving in [false, true]:
		for direction in [0, 3, 6, 9, 12, 15, 18, 21]:
			for age in [-1.0, 0.0, 0.02, 0.05, 0.08, 0.12]:
				residue.aim = Vector2.RIGHT.rotated(direction * TAU / 24.0)
				residue._animation.elapsed = 0.13
				residue._animation.moving = moving
				residue.fire_cd = residue.fire_interval - age if age >= 0 else 0.0
				water.age = residue.fire_interval - residue.fire_cd if residue.fire_cd > 0 else -1.0
				water.phase = 0.13
				water.walking = moving
				water.heading = residue.aim
				residue.queue_redraw()
				water.queue_redraw()
				for frame in 2:
					await process_frame
					await RenderingServer.frame_post_draw
				compared += 1
				if actual.get_texture().get_image().get_data() != expected.get_texture().get_image().get_data():
					failures += 1
					push_error("Different Water/Residues shooting pose: moving=%s direction=%d age=%f" % [moving, direction, age])
	print("RESIDUE_PRESENTATION_", "OK" if failures == 0 else "FAILED", ": ", compared, " pixel-identical comparisons; ", failures, " failures")
	actual.queue_free()
	expected.queue_free()
	for frame in 3: await process_frame
	quit(1 if failures else 0)
