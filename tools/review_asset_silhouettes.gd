extends SceneTree
## Diagnostic plates rendered by the same drawing functions as the live game.
class Board extends Node2D:
	const Art=preload("res://scripts/station_art.gd")
	const Props=preload("res://scripts/environment_props.gd")
	var page:=0
	func _draw() -> void:
		draw_rect(Rect2(0,0,960,540),Color("142b32"))
		var font:=ThemeDB.fallback_font
		draw_string(font,Vector2(20,23),["SILHUETAS COMPLETAS — MÁQUINAS","SILHUETAS COMPLETAS — PROPS","TOTENS — DESLIGADOS / RESTAURADOS"][page],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("aee8d6"))
		if page==0:
			var kinds: Array=["clarifier","tank","pump","control_room","manifold","purifier"]
			var widths: Array=[220.0,150.0,220.0,215.0,230.0,240.0]
			for i in range(6):
				var foot:=Vector2(160+(i%3)*320,250+(i/3)*260)
				_floor(Rect2(foot-Vector2(150,215),Vector2(300,220)))
				var prop: Dictionary=Props.create(kinds[i],foot,widths[i])
				Props.draw_foundation(self,prop)
				Props.draw(self,prop,7)
				draw_string(font,foot+Vector2(-100,18),kinds[i],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("d9e7db"))
		elif page==1:
			var kinds: Array=["crate","open_crate","stacked_crates","barrel","pallet","cabinet","barrier","spool"]
			for i in range(8):
				var foot:=Vector2(120+(i%4)*240,250+(i/4)*260)
				_floor(Rect2(foot-Vector2(110,210),Vector2(220,215)))
				var prop: Dictionary=Props.create(kinds[i],foot,105)
				Props.draw_foundation(self,prop)
				Props.draw(self,prop,7)
				draw_string(font,foot+Vector2(-95,18),kinds[i],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("d9e7db"))
		else:
			for i in range(8):
				var foot:=Vector2(120+(i%4)*240,250+(i/4)*260)
				_floor(Rect2(foot-Vector2(110,210),Vector2(220,215)))
				draw_set_transform(foot,0,Vector2(2,2))
				Art.draw_totem(self,Vector2(70,23),i%4,i>=4,7)
				draw_set_transform(Vector2.ZERO)
				draw_string(font,foot+Vector2(-95,18),"Sistema %d — %s"%[i%4+1,"online" if i>=4 else "offline"],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("d9e7db"))
	func _floor(r: Rect2) -> void:
		draw_rect(r,Color("394846"))
		for x in range(int(r.position.x),int(r.end.x),32): draw_line(Vector2(x,r.position.y),Vector2(x,r.end.y),Color("52605a"),1)
		for y in range(int(r.position.y),int(r.end.y),32): draw_line(Vector2(r.position.x,y),Vector2(r.end.x,y),Color("52605a"),1)

func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	root.content_scale_size=Vector2i(960,540)
	root.size=Vector2i(1440,810)
	var output:=OS.get_environment("P17_REVIEW_OUTPUT")
	if output.is_empty(): output="res://.runtime/integration_review"
	DirAccess.make_dir_recursive_absolute(output)
	var board:=Board.new()
	root.add_child(board)
	var names: Array=["21_silhuetas_maquinas","22_silhuetas_props","23_totens_estados"]
	for page in range(3):
		board.page=page
		board.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var error:=root.get_texture().get_image().save_png(output+"/"+names[page]+".png")
		if error!=OK: push_error("Cannot save diagnostic plate"); quit(1); return
	board.free()
	await process_frame
	print("ASSET_PLATES_OK: 3 renderer captures; 22 full silhouettes")
	quit(0)
