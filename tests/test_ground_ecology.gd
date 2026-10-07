extends SceneTree
## Ground integration: anchoring, bank moisture, root contact, alpha and reuse.
const W = preload("res://scripts/world.gd")
const Ground = preload("res://scripts/ground_ecology.gd")
const Art = preload("res://scripts/station_art.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: _run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _run() -> void:
	W.prepare_wetlands()
	check(Ground.surfaces.size()==4,"All four sectors receive anchored terrain")
	var ids: Array[int] = []
	var bytes := 0
	for index in range(Ground.surfaces.size()):
		var surface: Dictionary = Ground.surfaces[index]
		var r: Rect2 = W.REGIONS[index]
		check(surface.rect==r,"Cached ground bounds coincide with the platform")
		var image: Image = surface.texture.get_image()
		bytes += image.get_data_size()
		check(Vector2(image.get_size())==r.size,"Ground texture keeps one texel per world pixel")
		ids.append(surface.texture.get_instance_id())
		var field: Image = surface.field
		var dry := 1.0
		for y in range(80,int(r.size.y)-80,40):
			for x in range(80,int(r.size.x)-80,40):
				dry = minf(dry,field.get_pixel(x,y).r)
		check(field.get_pixel(8,int(r.size.y*0.5)).r>dry+0.35,"Water bank remains wetter than sheltered interior")
		var green := 0
		var covered := 0
		for y in range(8,int(r.size.y)-8,7):
			for x in range(6,30,4):
				var c := image.get_pixel(x,y)
				covered += 1
				if c.g>c.r*1.1 and c.g>c.b*1.1: green += 1
		check(green>covered*0.05,"Ground bank contains actual moss pixels, not a plain dark overlay")
		var tiles: Array[Dictionary] = Art.floor_tiles(r,index)
		var area := 0.0
		for tile in tiles:
			check(r.encloses(tile.rect),"Slab layout stays inside its platform")
			area += tile.rect.size.x*tile.rect.size.y
		check(is_equal_approx(area,r.size.x*r.size.y),"Slabs cover the floor without gaps")
		for crossing in W.Wetlands.CROSSINGS:
			if r.has_point(crossing.get_center()):
				check(image.get_pixelv(Vector2i(crossing.get_center()-r.position)).a==0,"Weathering does not cover a metal walking deck")
		var roots := 0
		for plant in W.Wetlands.plants(r):
			if plant.get("aquatic",false) or not r.grow(-8).has_point(plant.foot): continue
			check(field.get_pixelv(Vector2i(plant.foot-r.position)).g>0.2,"Fern roots connect to the ground influence field")
			roots += 1
			if roots>=12: break
		check(roots>=12,"Each sector has multiple terrestrial root contacts")
	check(bytes<16*1024*1024,"Cached ground textures stay within a 16 MiB budget")
	check(Ground.puddles.size()>=8,"Authored depressions produce shallow pools across the district")
	for puddle in Ground.puddles:
		var image: Image = puddle.texture.get_image()
		check(image.get_pixel(0,0).a==0 and image.get_pixel(image.get_width()-1,image.get_height()-1).a==0,"Puddle corners stay transparent")
		check(image.get_pixel(image.get_width()/2,image.get_height()/2).a>0.4,"Puddle has a visible wet center")
		var contact: Vector2 = puddle.rect.get_center()
		var sector := -1
		for index in W.REGIONS.size():
			if W.REGIONS[index].has_point(contact): sector=index
		check(sector>=0 and W.walkable(contact,1,sector),"A shallow puddle remains traversable ground")
	W.prepare_wetlands()
	for index in ids.size(): check(ids[index]==Ground.surfaces[index].texture.get_instance_id(),"Presentation reuses cached terrain instead of rebuilding it")
	var fern_image := Art.FERNS.get_image()
	if fern_image.is_compressed(): fern_image.decompress()
	check(fern_image.get_pixel(0,0).a<0.01,"Fern atlas has transparent surroundings")
	for crop in Art.FERN_CROPS:
		check(Rect2(Vector2.ZERO,Art.FERNS.get_size()).encloses(crop),"Fern source rectangle fits its atlas")
	print("GROUND_ECOLOGY_%s: %d checks; %d puddles; texture_MiB=%.2f; setup_ms=%.2f" % ["OK" if failures.is_empty() else "FAILED",checks,Ground.puddles.size(),float(bytes)/1048576,Ground.setup_usec/1000.0])
	quit(0 if failures.is_empty() else 1)
