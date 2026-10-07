extends SceneTree
const Intro = preload("res://scripts/prologue.gd")
var game: Node2D
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
 root.content_scale_size=Vector2i(960,540)
 root.size=Vector2i(1440,810)
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.sound.set_muted(true)
 game._start_prologue(true)
 game.prologue.phase="lab"
 game.prologue.step=7
 game.prologue.conversation.clear()
 game.prologue.elapsed=12
 for item in [["11_atras_nucleo",Vector2(925,435)],["12_frente_nucleo",Vector2(918,660)],["13_calibracao",Vector2(414,496)],["14_analise",Vector2(733,395)]]:
  game.prologue.pos=Intro.Lab.Set.point(item[1])
  game.prologue.step=1 if item[0]=="13_calibracao" else (2 if item[0]=="14_analise" else 7)
  print(item[0]," clear=",Intro.Lab.walkable(game.prologue.pos))
  for frame in range(5):
   game.queue_redraw()
   await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(OS.get_environment("P17_PROLOGUE_OUTPUT")+"/"+item[0]+".png")
 game.free()
 await process_frame
 quit()
