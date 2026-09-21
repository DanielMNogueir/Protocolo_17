extends SceneTree
## Extract only the cyan pulse tool from the existing official reference.
const ROOT := "res://assets/weapon_official/"

func _initialize() -> void:
	var img := Image.load_from_file(ROOT + "source.png")
	img = img.get_region(Rect2i(0, 0, img.get_width(), int(img.get_height() / 4)))
	img.convert(Image.FORMAT_RGBA8)
	var columns: Array[int] = []
	columns.resize(img.get_width())
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if minf(c.r, c.b) > 0.03 and c.r > c.g * 1.4 and c.b > c.g * 1.4:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				columns[x] += 1
	var frames: Array = []
	var start := -1
	for x in columns.size():
		if columns[x] > 0 and start < 0:
			start = x
		elif columns[x] == 0 and start >= 0:
			var near := false
			for next in range(x, mini(x + 8, columns.size())):
				near = near or columns[next] > 0
			if near:
				continue
			var rect := img.get_region(Rect2i(start, 0, x - start, img.get_height())).get_used_rect()
			rect.position.x += start
			if rect.size.x > 50:
				frames.append([rect.position.x, rect.position.y, rect.size.x, rect.size.y])
			start = -1
	if frames.size() != 4:
		push_error("Expected four pulse tools: " + str(frames))
		quit(1)
		return
	assert(img.save_png(ROOT + "pulse_tool.png") == OK)
	var file := FileAccess.open(ROOT + "frames.gd", FileAccess.WRITE)
	file.store_string("extends RefCounted\n# Extracted official pulse tool: down, left, right, up.\nconst RECTS = " + JSON.stringify(frames) + "\n")
	file.close()
	print("WEAPON_IMPORT_OK: ", frames)
	quit()
