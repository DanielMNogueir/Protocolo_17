extends SceneTree
const Water=preload("res://scripts/water_surface.gd")
const W=preload("res://scripts/world.gd")
var checks:=0
var failures: Array[String]=[]
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func sample(water: P17WaterSurface, p: Vector2) -> Color:
	return water.field_image.get_pixel(int(p.x/Water.FIELD_STEP),int(p.y/Water.FIELD_STEP))
func _run() -> void:
	var water:=Water.new()
	water.configure(W.SIZE,W.REGIONS,W.BRIDGES,W.PIER,W.BASINS)
	root.add_child(water)
	await process_frame
	check(water.show_behind_parent,"Surface is below terrain, bridges, actors and HUD")
	check(water.field_image.get_size()==Vector2i(640,450),"Depth data uses the bounded low-resolution field")
	check(water.field_image.get_data().size()==864000,"Static RGB field stays below one megabyte")
	check(sample(water,Vector2(600,930)).r>sample(water,Vector2(600,1010)).r+0.4,"Horizontal canal center is deeper than its bank")
	check(sample(water,Vector2(1280,400)).r>sample(water,Vector2(1118,400)).r+0.8,"Vertical trunk preserves depth falloff")
	check(sample(water,Vector2(1280,600)).g<0.05,"Vertical canal has a vertical flow vector")
	check(sample(water,Vector2(600,930)).g>0.95,"Cross-channel has a horizontal flow vector")
	check(sample(water,Vector2(1280,830)).g>0.05 and sample(water,Vector2(1280,830)).g<0.95,"Junction turns the current gradually")
	check(sample(water,Vector2(780,935)).b>0.8,"Bridge casts shade into the water below it")
	check(sample(water,Vector2(600,930)).b<0.01,"Open channel is free from unrelated structure shadow")
	check(sample(water,Vector2(450,1730)).b>0.7,"Pier casts a local contact shadow")
	check(water.pool_viewport.size==Vector2i(288,384),"Both reservoirs share one small render target")
	check(water.pool_material.get_shader_parameter("allow_pollution")==0.0,"East-side pools do not inherit the west-channel pollution tint")
	for i in range(water.pool_regions.size()):
		check(water.pool_regions[i].size==W.BASINS[i+1].grow(-8).size,"Pool samples retain one-to-one pixel scale")
	var original_texture:=water.field_texture
	water.present(Vector2(-300,-100),12,3)
	check(water.position==Vector2(-300,-100),"Water follows the exact camera offset")
	check(water.water_material.get_shader_parameter("water_time")==12.0,"Animation uses the shared game clock")
	check(water.pool_material.get_shader_parameter("water_time")==12.0,"Reservoirs share the same animation clock")
	check(water.water_material.get_shader_parameter("recovery")==1.0,"Recovery preserves the clean-water state")
	water.present(Vector2(-332,-120),13,0)
	check(water.field_texture==original_texture,"Camera/time changes do not rebuild depth data")
	check(water.water_material.get_shader_parameter("recovery")==0.0,"Unrestored water retains its restrained polluted tint")
	print("WATER_SURFACE_%s: %d checks; setup_ms=%.2f"%["OK" if failures.is_empty() else "FAILED",checks,water.setup_usec/1000.0])
	for failure in failures: push_error(failure)
	water.free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
