extends SceneTree
## GPU regression: world anchoring, visible motion, restrained change, foreground order.
const Water=preload("res://scripts/water_surface.gd")
const W=preload("res://scripts/world.gd")
class Foreground extends Node2D:
	func _draw() -> void: draw_rect(Rect2(30,30,40,40),Color("e3b65c"))
class ChannelPreview extends Node2D:
	var water: P17WaterSurface
	func _draw() -> void:
		for index in W.Wetlands.CHANNELS.size():
			water.draw_service_channel(self,Rect2(600+(index%4)*82,100+(index/4)*52,80,50),index)
var failures: Array[String]=[]
var checks:=0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func frame(water: P17WaterSurface, offset: Vector2, time: float) -> Image:
	water.present(offset,time,3)
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func difference(a: Color,b: Color) -> float:
	return maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))
func _run() -> void:
	root.content_scale_size=Vector2i(960,540)
	root.size=Vector2i(960,540)
	var foreground:=Foreground.new()
	root.add_child(foreground)
	var water:=Water.new()
	water.configure(W.SIZE,W.REGIONS,W.BRIDGES,W.PIER,W.BASINS,W.Wetlands.CHANNELS)
	foreground.add_child(water)
	var preview:=ChannelPreview.new()
	preview.water=water
	foreground.add_child(preview)
	for warmup in range(60): await process_frame
	var a: Image=await frame(water,Vector2(-960,-720),18)
	var b: Image=await frame(water,Vector2(-992,-736),18)
	var atlas_before:=water.pool_viewport.get_texture().get_image()
	var animated: Image=await frame(water,Vector2(-992,-736),19.5)
	var atlas_after:=water.pool_viewport.get_texture().get_image()
	for index in water.pool_regions.size():
		var region: Rect2=water.pool_regions[index]
		var tones: Dictionary={}
		var moving:=0
		for row in range(1,6):
			for column in range(1,6):
				var point: Vector2i=Vector2i(region.position+region.size*Vector2(column/6.0,row/6.0))
				var original:=atlas_before.get_pixelv(point)
				tones[original.to_rgba32()]=true
				if difference(original,atlas_after.get_pixelv(point))>0.009: moving+=1
		check(tones.size()>2,"Packed water region %d renders a varied surface" % index)
		check(moving>0,"Packed water region %d animates" % index)
	var changed:=0
	var total:=0
	var mean_delta:=0.0
	var colors: Dictionary={}
	for y in range(190,250,5):
		for x in range(240,420,5):
			var original:=a.get_pixel(x,y)
			var shifted:=b.get_pixel(x-32,y-16)
			check(difference(original,shifted)<0.009,"Water pixels stay anchored to the world during camera motion")
			colors[original.to_rgba32()]=true
			var delta:=difference(shifted,animated.get_pixel(x-32,y-16))
			if delta>0.009: changed+=1
			mean_delta+=delta
			total+=1
	check(colors.size()>20,"Water has a varied tonal surface, not a flat field")
	check(changed>total*0.05,"The shader produces visible surface movement")
	check(mean_delta/total<0.07,"Movement does not flash or overwhelm the palette")
	check(difference(a.get_pixel(50,50),Color("e3b65c"))<0.009,"Foreground remains above the water")
	print("WATER_RENDERING_%s: %d checks; %d colors; %d/%d moving samples; mean_delta=%.4f"%["OK" if failures.is_empty() else "FAILED",checks,colors.size(),changed,total,mean_delta/total])
	for failure in failures: push_error(failure)
	foreground.free()
	water=null
	foreground=null
	for cleanup in range(5): await process_frame
	quit(0 if failures.is_empty() else 1)
