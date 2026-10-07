extends SceneTree
## Real intro UI: long text, speaker swap, screen anchoring and mouse actions.
const Intro=preload("res://scripts/prologue.gd")
const DialogueUI=preload("res://scripts/dialogue_panel.gd")
class Shell extends "res://scripts/main.gd":
 func _load_settings() -> void: pass
 func _save_settings() -> void: pass
 func _save_checkpoint() -> void: pass
var checks:=0
var failures: Array[String]=[]
func _initialize() -> void: _run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok: failures.append(message)
func capture(game: Node2D) -> Image:
 for n in range(5):
  game.queue_redraw()
  await process_frame
  await RenderingServer.frame_post_draw
 return root.get_texture().get_image()
func click(game: Node2D,point: Vector2) -> void:
 var event:=InputEventMouseButton.new()
 event.button_index=MOUSE_BUTTON_LEFT
 event.pressed=true
 event.position=point
 game._unhandled_input(event)
func _run() -> void:
 var game:=Shell.new()
 root.add_child(game)
 game.set_process(false)
 game.sound.set_muted(true)
 game._start_prologue(true)
 var text: String=Intro.CONTEXT[0][1]
 for size in [Vector2i(960,540),Vector2i(1280,720),Vector2i(960,640)]:
  root.content_scale_size=size
  root.size=size
  await capture(game)
  var ui:=DialogueUI.layout(Vector2(size))
  var line:=""
  var lines:=1
  for word in text.split(" "):
   var candidate: String=word if line.is_empty() else line+" "+word
   if ThemeDB.fallback_font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,DialogueUI.FONT_SIZE).x>ui.body.size.x:
    lines+=1
    line=word
   else: line=candidate
  check(lines*DialogueUI.LINE_HEIGHT<=ui.body.size.y,"Complete world narration fits above the controls at "+str(size))
  for button in game.buttons:
   check(Rect2(Vector2.ZERO,Vector2(size)).encloses(button.rect),"Intro controls remain fully on screen at "+str(size))
  check(not ui.portrait.intersects(ui.body),"Portrait never overlaps the speech")
  check(not ui.fast.intersects(ui.advance),"Instant text and advance have separate click targets")
 root.content_scale_size=Vector2i(960,540)
 root.size=Vector2i(960,540)
 game.prologue=Intro.new()
 await capture(game)
 click(game,DialogueUI.layout(Vector2(960,540)).body.get_center())
 check(game.prologue.text_complete() and game.prologue.phase=="context","Clicking speech completes the current line first")
 await capture(game)
 click(game,DialogueUI.layout(Vector2(960,540)).advance.get_center())
 check(game.prologue.phase=="lab","The advance control enters the playable laboratory")
 game.prologue.step=2
 game.prologue._complete_interaction()
 game.prologue.revealed=true
 var terminal: Image=await capture(game)
 var ai_source:=DialogueUI.AI_PORTRAIT.get_image()
 var ai_area: Rect2=DialogueUI.layout(Vector2(960,540)).portrait.grow(-4)
 for uv in [Vector2(0.4,0.3),Vector2(0.55,0.45),Vector2(0.65,0.6)]:
  var point:=Vector2i(ai_area.position+ai_area.size*uv)
  var source_point:=Vector2i((Vector2(point)+Vector2(0.5,0.5)-ai_area.position)/ai_area.size*Vector2(ai_source.get_size()))
  var expected:=ai_source.get_pixelv(source_point)
  var actual:=terminal.get_pixelv(point)
  check(maxf(absf(expected.r-actual.r),maxf(absf(expected.g-actual.g),absf(expected.b-actual.b)))<0.035,"IA speech renders the new holographic portrait")
 var speech: String=game.prologue.text()
 for n in range(600): game.prologue.tick(0.05,Vector2.RIGHT,game.prologue.pos,true,true,true,true)
 check(game.prologue.text()==speech,"Reading or holding acceleration leaves the rendered speaker's line active")
 game.prologue.advance()
 game.prologue.revealed=true
 var human: Image=await capture(game)
 var portrait: Rect2=DialogueUI.layout(Vector2(960,540)).portrait
 var changed:=0
 for y in range(int(portrait.position.y),int(portrait.end.y),3):
  for x in range(int(portrait.position.x),int(portrait.end.x),3):
   if terminal.get_pixel(x,y).to_rgba32()!=human.get_pixel(x,y).to_rgba32(): changed+=1
 check(changed>500,"Switching the real speaker replaces the left portrait")
 var anchored: Image=await capture(game)
 game.prologue_camera+=Vector2(40,20)
 var moved: Image=await capture(game)
 for y in range(380,518,10):
  for x in range(30,930,17):
   check(anchored.get_pixel(x,y).to_rgba32()==moved.get_pixel(x,y).to_rgba32(),"Dialogue stays at the bottom while the world camera moves")
 var previous: bool=game.prologue.fast_text
 click(game,DialogueUI.layout(Vector2(960,540)).fast.get_center())
 check(game.prologue.fast_text!=previous,"Instant text can still be toggled with the mouse")
 await capture(game)
 for button in game.buttons:
  if button.id=="intro_skip": click(game,button.rect.get_center()); break
 check(game.mode=="title" and game.prologue==null,"Skip remains reachable while dialogue is displayed")
 print("DIALOGUE_PANEL_%s: %d checks; %d swapped portrait samples; %d failures"%["OK" if failures.is_empty() else "FAILED",checks,changed,failures.size()])
 for failure in failures: push_error(failure)
 game.free()
 for n in range(5): await process_frame
 quit(0 if failures.is_empty() else 1)
