extends SceneTree
## GPU checks: motion inside actual atlas mouths, camera anchoring and occlusion.
const Props = preload("res://scripts/environment_props.gd")
const H = preload("res://scripts/hydraulic_effects.gd")
const W = preload("res://scripts/world.gd")
const Objectives = preload("res://scripts/objective_visual.gd")
var failures: Array[String] = []
var checks := 0

class Fixture extends Node2D:
	var time := 12.0
	var online := false
	var overlay := false
	var machine: Dictionary
	var objective := -1
	func _draw() -> void:
		draw_rect(Rect2(-20,-20,900,600),Color("102d36"))
		if objective>=0:
			Objectives.draw_body(self,Vector2(350,420),objective,online,time)
		else:
			Props.draw_foundation(self,machine)
			Props.draw(self,machine,time,online)
		H.draw_discharge(self,Vector2(600,220),Vector2.RIGHT,time,online)
		H.draw_discharge(self,Vector2(790,300),Vector2.LEFT,time,online)
		if overlay: draw_rect(Rect2(167,343,28,35),Color("e3b65c"))

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func delta(a: Color, b: Color) -> float:
	return maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))

func capture(fixture: Fixture, time: float) -> Image:
	fixture.time = time
	fixture.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func moving(a: Image, b: Image, r: Rect2) -> int:
	var count := 0
	for y in range(int(r.position.y),int(r.end.y)):
		for x in range(int(r.position.x),int(r.end.x)):
			if delta(a.get_pixel(x,y),b.get_pixel(x,y))>0.03: count += 1
	return count

func _run() -> void:
	root.content_scale_size = Vector2i(900,600)
	root.size = Vector2i(900,600)
	var fixture := Fixture.new()
	fixture.machine = Props.create("clarifier",Vector2(170,390),300)
	root.add_child(fixture)
	for warmup in range(4): await process_frame
	var a := await capture(fixture,12)
	var b := await capture(fixture,12.137)
	var mouth := H.point(fixture.machine,Vector2(281,583))
	var landing := H.point(fixture.machine,Vector2(299,657))
	var falling := Rect2(mouth-Vector2(7,0),Vector2(23,landing.y-mouth.y))
	check(moving(a,b,falling)>20,"Painted clarifier waterfall now has visible descending motion")
	check(moving(a,b,Rect2(602,213,65,20))>10,"Left reservoir inlet has animated flow and foam")
	check(moving(a,b,Rect2(726,293,63,20))>10,"Right reservoir inlet flows inward and animates")
	fixture.position = Vector2(20,10)
	var shifted := await capture(fixture,12.137)
	for y in range(int(falling.position.y),int(falling.end.y),4):
		for x in range(int(falling.position.x),int(falling.end.x),4):
			check(delta(b.get_pixel(x,y),shifted.get_pixel(x+20,y+10))<0.01,"Machine water stays registered when camera moves")
	fixture.position = Vector2.ZERO
	fixture.online = true
	var active := await capture(fixture,12)
	check(moving(a,active,Rect2(600,210,70,24))>20,"Restoration increases the inlet stream")
	fixture.overlay = true
	var covered := await capture(fixture,12)
	check(delta(covered.get_pixel(178,359),Color("e3b65c"))<0.01,"Foreground drawn after the machine covers the water")
	fixture.overlay = false
	for kind in ["tank","pump","manifold","purifier"]:
		fixture.machine = Props.create(kind,Vector2(300,420),140)
		var before := await capture(fixture,12)
		var after := await capture(fixture,12.137)
		check(moving(before,after,fixture.machine.visual_bounds.grow(14))>0,"%s animates at its actual mouth or sight glass" % kind)
		for outlet in H.outlets(fixture.machine):
			check(fixture.machine.visual_bounds.grow(2).has_point(outlet.mouth),"%s outlet starts on the machine" % kind)
			check(outlet.landing.y>outlet.mouth.y,"%s droplets fall toward the ground" % kind)
	for index in [0,2,3]:
		fixture.objective = index
		var before := await capture(fixture,12)
		var after := await capture(fixture,12.137)
		var bounds: Rect2 = Objectives.placement(Vector2(350,420),index).visual_bounds
		check(moving(before,after,bounds)>8,"Objective %d animates the exposed water after restoration" % index)
	for sector in range(4):
		var machines: Array[Dictionary] = W.props()+W.building_objects()
		machines.append(W.clarifier())
		var animated_count := 0
		for machine in machines:
			if not machine.has("visual_bounds"): continue
			if W.REGIONS[sector].has_point(machine.visual_bounds.get_center()) and machine.kind in ["clarifier","tank","pump","manifold","purifier"]:
				animated_count += 1
				check(not W._hydraulic_online(machine,sector),"Sector %d remains low pressure before repair" % sector)
				check(W._hydraulic_online(machine,sector+1),"Sector %d receives pressure after repair" % sector)
		check(animated_count>0,"Sector %d contains animated hydraulic equipment" % sector)
	print("HYDRAULICS_%s: %d checks; %d failures" % ["OK" if failures.is_empty() else "FAILED",checks,failures.size()])
	for failure in failures: push_error(failure)
	fixture.free()
	for cleanup in range(4): await process_frame
	quit(0 if failures.is_empty() else 1)
