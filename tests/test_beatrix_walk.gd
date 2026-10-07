extends SceneTree
const Art = preload("res://scripts/beatrix_art.gd")

class View extends Node2D:
	var facing := Vector2.RIGHT
	var pose_time := 0.0
	func _draw() -> void:
		Art.draw(self,Vector2(64,64)-Vector2(0,13),facing,pose_time,true)

func _initialize() -> void:
	_run.call_deferred()

func _capture(view: View, time: float) -> Image:
	view.pose_time = time
	view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func _leg_change(a: Image, b: Image) -> float:
	var changed := 0
	var occupied := 0
	for y in range(43,65):
		for x in range(20,108):
			var first := a.get_pixel(x,y).a>0.3
			var second := b.get_pixel(x,y).a>0.3
			if first or second: occupied += 1
			if first != second: changed += 1
	return float(changed)/maxi(occupied,1)

func _head_center(image: Image) -> float:
	var total := 0.0
	var count := 0
	for y in range(2,35):
		for x in range(20,108):
			var color := image.get_pixel(x,y)
			if color.a>0.3 and color.r>color.g*1.2 and color.g>color.b*1.05 and color.r>0.14:
				total += x
				count += 1
	return total/maxi(count,1)

func _run() -> void:
	root.content_scale_size = Vector2i(128,96)
	root.size = Vector2i(128,96)
	root.transparent_bg = true
	var view := View.new()
	root.add_child(view)
	var failures: Array[String] = []
	var output := OS.get_environment("P17_BEATRIX_WALK_OUTPUT")
	if not output.is_empty(): DirAccess.make_dir_recursive_absolute(output)
	for direction_index in range(8):
		var facing := Vector2.RIGHT.rotated(direction_index*PI/4)
		view.facing = facing
		var frames: Array[Image] = []
		for time in [0.01,0.14,0.26,0.39]:
			var frame := await _capture(view,time)
			frames.append(frame)
			if not output.is_empty(): frame.save_png(output+"/direction_%d_phase_%d.png" % [direction_index,frames.size()-1])
		for phase in range(3):
			var change := _leg_change(frames[phase],frames[phase+1])
			var head_shift := absf(_head_center(frames[phase])-_head_center(frames[phase+1]))
			print("BEATRIX_WALK direction=%s phase=%d legs=%.3f head_shift=%.1f" % [facing,phase,change,head_shift])
			if change<0.12: failures.append("Walking legs barely change in direction %s phase %d" % [facing,phase])
			if head_shift>3.0: failures.append("Upper body jumps in direction %s phase %d" % [facing,phase])
	print("BEATRIX_WALK_%s: %d failures" % ["OK" if failures.is_empty() else "FAILED",failures.size()])
	for failure in failures: push_error(failure)
	view.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
