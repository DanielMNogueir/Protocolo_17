extends SceneTree
var game: Node2D
var output:=OS.get_environment("P17_DISTRICT_CAPTURE_DIR")
func _initialize() -> void:
 _run.call_deferred()
func _run() -> void:
 if output.is_empty(): output="res://captures/distrito-integrado"
 DirAccess.make_dir_recursive_absolute(output)
 root.content_scale_size=Vector2i(960,540)
 root.size=Vector2i(1440,810)
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.sound.set_muted(true)
 game.clock=7.0
 game.pointer=Vector2(-100,-100)
 game.mode="play"
 var reviews: Array=[
  ["01-cais-captacao",0,Vector2(530,1190)],
  ["02-cais-carga",0,Vector2(430,1490)],
  ["03-ponte-norte",1,Vector2(770,925)],
  ["04-energia",1,Vector2(610,440)],
  ["05-ponte-central",2,Vector2(1280,610)],
  ["06-filtragem",2,Vector2(2060,410)],
  ["07-distribuicao",3,Vector2(1960,1330)],
  ["08-reserva",3,Vector2(1700,1510)],
  ["09-passarela-cais",0,Vector2(460,1400)],
 ]
 for review in reviews:
  game.sim.start(review[1])
  game.sim.enemies.clear()
  game.sim.pos=review[2]
  game.camera_pos=review[2]
  game._clamp_camera()
  game.queue_redraw()
  for frame in range(5):
   await process_frame
   await RenderingServer.frame_post_draw
  assert(root.get_texture().get_image().save_png(output+"/"+review[0]+".png")==OK)
 print("DISTRICT_REVIEW_OK: 9 views; shadows=",game.district_effects.caster_count," setup_ms=",game.district_effects.setup_usec/1000.0)
 game.queue_free()
 game=null
 for cleanup in range(5): await process_frame
 quit(0)
