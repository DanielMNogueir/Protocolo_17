extends SceneTree
## Exercise the real movement, dash and projectile APIs at authored crossings.
const W = preload("res://scripts/world.gd")
const S = preload("res://scripts/simulation.gd")
const Wetlands = preload("res://scripts/wetlands.gd")
const Water = preload("res://scripts/water_surface.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: _run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var sim := S.new()
	sim.start()
	sim.enemies.clear()
	for bridge in Wetlands.CROSSINGS:
		var stage := 0 if bridge.position.y>1200 and bridge.position.x<1200 else (1 if bridge.position.y<1000 else 3)
		sim.start(stage)
		sim.enemies.clear()
		for offset in [-22.0,0.0,22.0]:
			for direction in [-1.0,1.0]:
				var center := bridge.get_center()+Vector2(offset,0)
				var extent: float = bridge.size.y*0.5+18.0
				var from: Vector2 = center-Vector2(0,extent)*direction
				var to: Vector2 = center+Vector2(0,extent)*direction
				check(W.walkable(from,S.PLAYER_RADIUS,stage),"The bridge approach is clear before walking")
				sim.pos = from
				sim.velocity = Vector2.ZERO
				for frame in range(120):
					if sim.pos.distance_to(to)<3: break
					sim.tick(1.0/120,(to-sim.pos).normalized(),to,false,false,false)
					var clear := W.walkable(sim.pos,S.PLAYER_RADIUS,stage)
					check(clear,"Bridge motion stays on the walking deck")
					if not clear: break
				check(sim.pos.distance_to(to)<5,"Both walking directions and side lanes cross the service canal")
	# Pressing against a visibly open canal cannot enter the water, even in a dash.
	sim.start()
	sim.enemies.clear()
	sim.pos = Vector2(570,1355)
	sim.velocity = Vector2.ZERO
	sim.dash_cd = 0
	for frame in range(70):
		sim.tick(1.0/120,Vector2.DOWN,Vector2(570,1490),false,frame==0,false)
		check(W.walkable(sim.pos,S.PLAYER_RADIUS,0),"Dash and movement cannot enter channel water")
	check(sim.pos.y<1376,"The open water remains a movement barrier")
	check(sim._wall_fraction(Vector2(570,1355),Vector2(570,1490),3)==INF,"Pulses cross open water without an invisible wall")
	# Exercise actual normal-damage shots on a target across the drain.
	sim.start()
	sim.pos = Vector2(570,1480)
	sim.invuln = 999
	var target: Dictionary = sim.enemies[0].duplicate()
	target.pos = Vector2(570,1355)
	target.phase = "windup"
	target.warning = 999.0
	target.hp = 3
	target.max_hp = 3
	sim.enemies = [target]
	for frame in range(240):
		sim.tick(1.0/120,Vector2.ZERO,target.pos,true,false,false)
		if sim.enemies.is_empty(): break
	check(sim.enemies.is_empty() and sim.kills==1,"Real projectiles damage an enemy on the opposite maintenance platform")
	# Tall foliage is Y-sorted; its roots and shallow puddles introduce no solids.
	W.prepare_wetlands()
	var plants := Wetlands.plants(Rect2(Vector2.ZERO,W.SIZE))
	check(plants.size()>200,"Wetland beds contain grouped vegetation throughout the district")
	for plant in plants:
		check(is_equal_approx(plant.y,plant.foot.y),"Vegetation depth follows its ground contact")
		check(plant.bounds.has_point(plant.foot-Vector2(0,1)),"Vegetation bounds include its visible base")
	var water := Water.new()
	water.configure(W.SIZE,W.REGIONS,W.BRIDGES,W.PIER,W.BASINS,Wetlands.CHANNELS)
	root.add_child(water)
	await process_frame
	check(water.pool_regions.size()==W.BASINS.size()-1+Wetlands.CHANNELS.size(),"All water features share the compact atlas")
	check(water.pool_viewport.size.x*water.pool_viewport.size.y<1400000,"Packed atlas stays bounded as water coverage grows")
	for i in range(water.pool_regions.size()):
		check(Rect2(Vector2.ZERO,Vector2(water.pool_viewport.size)).encloses(water.pool_regions[i]),"Packed water stays within the render target")
		for j in range(i+1,water.pool_regions.size()):
			check(not water.pool_regions[i].intersects(water.pool_regions[j]),"Packed water regions do not overlap")
	for i in range(Wetlands.CHANNELS.size()):
		check(water.pool_regions[water.service_channel_offset+i].size==Wetlands.CHANNELS[i].grow(-3).size,"Channel water is sampled at its actual size")
	water.free()
	for cleanup in range(3): await process_frame
	print("WETLANDS_%s: %d checks; %d plants; %d failures" % ["OK" if failures.is_empty() else "FAILED",checks,plants.size(),failures.size()])
	quit(0 if failures.is_empty() else 1)
