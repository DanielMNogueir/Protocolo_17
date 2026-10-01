extends SceneTree
## Follow opaque connected silhouettes in the FULL atlas, beyond the selected crop.
## This catches a missing pipe or a truncated base even when the crop is in range.
const Art = preload("res://scripts/station_art.gd")
const Props = preload("res://scripts/environment_props.gd")
const Energy = preload("res://scripts/energy_station.gd")
var failures: Array[String]=[]
var checks := 0
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func _run() -> void:
	_audit("res://assets/station/structures_atlas.png",Art.STRUCTURE_CROPS,[ Vector2i(262,447),Vector2i(681,420),Vector2i(1052,507),Vector2i(234,932),Vector2i(685,954),Vector2i(1045,992) ],Art.STRUCTURE_CONTOURS)
	_audit("res://assets/station/totems_atlas.png",Art.TOTEM_CROPS,[ Vector2i(174,470),Vector2i(475,396),Vector2i(772,382),Vector2i(1082,454),Vector2i(172,973),Vector2i(474,890),Vector2i(773,882),Vector2i(1083,949) ])
	_audit("res://assets/environment/props/industrial_props_atlas.png",Props.CROPS,[ Vector2i(248,263),Vector2i(696,281),Vector2i(1140,267),Vector2i(1564,275),Vector2i(245,670),Vector2i(679,664),Vector2i(1126,666),Vector2i(1585,662) ])
	var station=load("res://scenes/structures/energy_station.tscn").instantiate()
	var control: Sprite2D=station.get_node("VisualMain/ControlRoom")
	check(control.texture.region==Energy.CONTROL_CROP,"Editor and runtime share full control-room crop")
	var generator: Polygon2D=station.get_node("VisualMain/Generator")
	check(generator.uv.size()==Art.STRUCTURE_CONTOURS[5].size(),"Editor uses the full isolated generator contour")
	for i in range(generator.uv.size()):
		check(generator.uv[i].is_equal_approx(Art.STRUCTURE_CONTOURS[5][i]),"Editor and runtime share the same source outline")
		check(generator.polygon[i].is_equal_approx(generator.uv[i]-Energy.GENERATOR_CROP.get_center()),"UV and geometry map identically, without distortion")
	for index in 2:
		var node: Node2D=control if index==0 else generator
		var crop: Rect2=Energy.CONTROL_CROP if index==0 else Energy.GENERATOR_CROP
		var bounds: Rect2=Energy.CONTROL_VISUAL if index==0 else Energy.GENERATOR_VISUAL
		check(is_equal_approx(node.scale.x,node.scale.y),"Scene equipment scales uniformly")
		check(is_equal_approx(bounds.size.x/crop.size.x,bounds.size.y/crop.size.y),"Runtime equipment scales uniformly")
		var actual:=Rect2(Energy.WORLD_ORIGIN+node.position-crop.size*node.scale*0.5,crop.size*node.scale)
		check(actual.position.is_equal_approx(bounds.position) and actual.size.is_equal_approx(bounds.size),"Scene and runtime use identical pivots")
	station.free()
	for failure in failures: push_error(failure)
	print("ASSET_SILHOUETTES_%s: %d checks; %d failures"%["OK" if failures.is_empty() else "FAILED",checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func _audit(path: String,crops: Array,seeds: Array,contours: Dictionary={}) -> void:
	var img:=Image.load_from_file(path)
	img.convert(Image.FORMAT_RGBA8)
	var data:=img.get_data()
	var w:=img.get_width()
	var h:=img.get_height()
	var seen:=PackedByteArray()
	seen.resize(w*h)
	for index in range(seeds.size()):
		var seed: Vector2i=seeds[index]
		var queue:=PackedInt32Array([seed.y*w+seed.x])
		seen[queue[0]]=index+1
		var lo:=seed
		var hi:=seed
		var cursor:=0
		var intact:=true
		var outline:=PackedVector2Array(contours.get(index,[]))
		while cursor<queue.size():
			var n:=queue[cursor]
			cursor+=1
			var x:=n%w
			var y:=n/w
			if contours.has(index) and not Geometry2D.is_point_in_polygon(Vector2(x+0.5,y+0.5),outline): intact=false
			lo=Vector2i(mini(lo.x,x),mini(lo.y,y))
			hi=Vector2i(maxi(hi.x,x),maxi(hi.y,y))
			for dy in [-1,0,1]:
				for dx in [-1,0,1]:
					var nx: int=x+dx
					var ny: int=y+dy
					if nx<0 or ny<0 or nx>=w or ny>=h: continue
					var next:=ny*w+nx
					if seen[next]==0 and data[next*4+3]>=32:
						seen[next]=index+1
						queue.append(next)
		var measured:=Rect2(Vector2(lo),Vector2(hi-lo+Vector2i.ONE))
		check(queue.size()>2000,"Audit found a complete machine, not a small speck")
		check(Rect2(Vector2.ZERO,Vector2(w,h)).encloses(crops[index]),"Source crop stays inside atlas")
		check(crops[index].encloses(measured.grow(1)),"FULL SILHOUETTE: %s #%d ink=%s crop=%s"%[path,index,measured,crops[index]])
		if contours.has(index):
			check(intact,"Contour preserves every original opaque silhouette pixel")
			var clean:=true
			# Scan the entire outline's bounds for pixels belonging to another machine.
			var polygon_bounds:=Rect2(contours[index][0],Vector2.ZERO)
			for point in contours[index]: polygon_bounds=polygon_bounds.expand(point)
			for y in range(maxi(0,int(polygon_bounds.position.y)),mini(h,int(ceil(polygon_bounds.end.y)))):
				for x in range(maxi(0,int(polygon_bounds.position.x)),mini(w,int(ceil(polygon_bounds.end.x)))):
					var n:=y*w+x
					if data[n*4+3]>=32 and seen[n]!=index+1 and Geometry2D.is_point_in_polygon(Vector2(x+0.5,y+0.5),outline): clean=false
			check(clean,"Contour excludes fragments of every neighbouring machine")
		print(path.get_file()," #",index," ink=",measured," crop=",crops[index])
