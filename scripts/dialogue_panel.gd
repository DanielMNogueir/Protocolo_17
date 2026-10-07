class_name P17DialoguePanel
extends RefCounted
## Screen-space RPG dialogue frame; speaker identity remains separate from text.
const Beatrix = preload("res://scripts/beatrix_art.gd")
const AI_PORTRAIT: Texture2D = preload("res://assets/prologue/ai_portrait_v1.png")
const INK := Color("0b202a")
const TEXT := Color("e5ece3")
const CYAN := Color("7de0cf")
const BRONZE := Color("a58c65")
const MUTED := Color("9eb9b8")
const FONT_SIZE := 16
const LINE_HEIGHT := 24

static func layout(size: Vector2) -> Dictionary:
 var frame:=Rect2(20,size.y-170,size.x-40,154)
 return {"frame":frame,
  "portrait":Rect2(frame.position+Vector2(13,13),Vector2(108,108)),
  "body":Rect2(frame.position+Vector2(139,32),Vector2(frame.size.x-179,80)),
  "advance":Rect2(frame.end-Vector2(394,29),Vector2(128,22)),
  "fast":Rect2(frame.end-Vector2(254,29),Vector2(238,22))}

static func _contour(rect: Rect2,cut: float=7) -> PackedVector2Array:
 var p:=rect.position
 var e:=rect.end
 return PackedVector2Array([p+Vector2(cut,0),Vector2(e.x-cut,p.y),Vector2(e.x,p.y+cut),e-Vector2(0,cut),e-Vector2(cut,0),Vector2(p.x+cut,e.y),Vector2(p.x,e.y-cut),p+Vector2(0,cut)])

static func _outline(canvas: Node2D,rect: Rect2,color: Color,cut: float=7) -> void:
 var points:=_contour(rect,cut)
 points.append(points[0])
 canvas.draw_polyline(points,color,1)

static func _frame(canvas: Node2D,rect: Rect2,accent: Color) -> void:
 canvas.draw_colored_polygon(_contour(Rect2(rect.position+Vector2(0,4),rect.size),9),Color("030e16",0.65))
 canvas.draw_colored_polygon(_contour(rect,9),Color("172a30"))
 _outline(canvas,rect,BRONZE,9)
 canvas.draw_colored_polygon(_contour(rect.grow(-3),7),Color("506466"))
 canvas.draw_colored_polygon(_contour(rect.grow(-5),5),Color(INK,0.98))
 _outline(canvas,rect.grow(-6),Color("2f4e55"),4)
 canvas.draw_line(rect.position+Vector2(15,4),Vector2(rect.end.x-15,rect.position.y+4),Color("d6bb87",0.7),1)
 canvas.draw_line(Vector2(rect.position.x+16,rect.end.y-33),rect.end-Vector2(16,33),Color("36555b"),1)
 # Machined corner fasteners and short emissive inlays, rather than a flat box.
 for x in [rect.position.x+9,rect.end.x-10]:
  for y in [rect.position.y+10,rect.end.y-10]:
   canvas.draw_rect(Rect2(x-2,y-2,4,4),Color("07151e"))
   canvas.draw_rect(Rect2(x-1,y-1,2,2),Color("c0aa7b"))
 for x in [rect.position.x+23,rect.end.x-59]:
  canvas.draw_rect(Rect2(x,rect.position.y+4,36,2),Color(accent,0.75))

static func _speaker(canvas: Node2D,rect: Rect2,kind: String,accent: Color,time: float) -> void:
 canvas.draw_colored_polygon(_contour(rect,5),Color("243d43"))
 canvas.draw_colored_polygon(_contour(rect.grow(-2),4),Color("071a24"))
 _outline(canvas,rect,BRONZE,5)
 for y in range(int(rect.position.y)+7,int(rect.end.y)-3,6):
  canvas.draw_line(Vector2(rect.position.x+4,y),Vector2(rect.end.x-4,y),Color("35565a",0.18),1)
 if kind=="beatrix":
  Beatrix.portrait(canvas,rect.grow(-4))
 elif kind=="terminal":
  var area:=rect.grow(-4)
  var scale_value:=minf(area.size.x/AI_PORTRAIT.get_width(),area.size.y/AI_PORTRAIT.get_height())
  var extent:=AI_PORTRAIT.get_size()*scale_value
  canvas.draw_texture_rect(AI_PORTRAIT,Rect2(area.get_center()-extent*0.5,extent),false)
 elif kind=="aurora":
  var c:=rect.get_center()
  canvas.draw_arc(c,31,0,TAU,48,Color("5b8b91"),1)
  canvas.draw_arc(c,23,0,TAU,48,Color("2e565e"),1)
  for n in range(3):
   var r:=Rect2(c+Vector2(-20+n*15,-17-n%2*13),Vector2(12,39+n%2*13))
   canvas.draw_rect(r,Color("41636a"))
   for y in range(int(r.position.y)+5,int(r.end.y)-3,7): canvas.draw_rect(Rect2(r.position.x+4,y,4,2),accent)
  canvas.draw_polyline(PackedVector2Array([c+Vector2(-27,24),c+Vector2(-12,17),c+Vector2(6,25),c+Vector2(27,16)]),Color("84ba92"),3)
 else:
  # Major 0's radio channel keeps a communication icon.
  var screen:=Rect2(rect.position+Vector2(17,20),Vector2(74,52))
  canvas.draw_rect(screen.grow(5),Color("40545a"))
  canvas.draw_rect(screen.grow(3),Color("142b34"))
  canvas.draw_rect(screen,Color("081923"))
  _outline(canvas,screen,Color(accent,0.6),0)
  for n in range(13):
   var height:=5+absf(sin(time*3.2+n*0.7))*23
   canvas.draw_rect(Rect2(screen.position+Vector2(6+n*5,26-height/2),Vector2(2,height)),Color(accent,0.85))
  canvas.draw_rect(Rect2(rect.position+Vector2(28,80),Vector2(52,3)),Color("5d7777"))
  for n in range(3): canvas.draw_rect(Rect2(rect.position+Vector2(36+n*14,90),Vector2(5,2)),accent)
 canvas.draw_rect(Rect2(rect.position+Vector2(11,rect.size.y-3),Vector2(29,2)),accent)

static func draw(canvas: Node2D,size: Vector2,speaker: String,label: String,text: String,complete: bool,fast: bool,time: float,alarm: bool=false,next_label: String="") -> void:
 var parts:=layout(size)
 var frame: Rect2=parts.frame
 var accent:=Color("ef8c98") if alarm and speaker=="terminal" else CYAN
 _frame(canvas,frame,accent)
 _speaker(canvas,parts.portrait,speaker,accent,time)
 # The brass name tab is visually attached to the portrait and the main frame.
 var width:=maxf(153,ThemeDB.fallback_font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x+28)
 var tab:=Rect2(frame.position+Vector2(133,-13),Vector2(width,26))
 canvas.draw_colored_polygon(_contour(tab,4),Color("142c35"))
 _outline(canvas,tab,BRONZE,4)
 if not label.is_empty(): canvas._text(label,tab.position+Vector2(13,17),10,accent)
 else:
  for n in range(16): canvas.draw_rect(Rect2(tab.position+Vector2(14+n*7,13-absf(sin(time*3+n))*4),Vector2(3,3+absf(sin(time*3+n))*8)),accent)
 canvas._wrapped(text,parts.body,FONT_SIZE,TEXT,LINE_HEIGHT)
 canvas._text("ENTER: AVANÇAR  •  SEGURE: ACELERAR",frame.position+Vector2(16,frame.size.y-13),8,MUTED)
 canvas._text("AGUARDANDO VOCÊ" if complete else "RECEBENDO FALA",frame.position+Vector2(281,frame.size.y-13),8,Color(accent,0.75))
 var action:=next_label if not next_label.is_empty() and complete else ("AVANÇAR / ENTER" if complete else "COMPLETAR / ENTER")
 canvas._button(parts.advance,action,"intro_next",false)
 canvas._button(parts.fast,"FALAS INSTANTÂNEAS: "+("SIM" if fast else "NÃO")+" / TAB","intro_fast",false)
 # Clicking the speech itself also completes/advances, without stealing footer controls.
 canvas.buttons.append({"rect":parts.body,"id":"intro_next"})
 if complete:
  var p:=Vector2(frame.end.x-22,frame.position.y+105+sin(time*3)*2)
  canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(-5,-3),p+Vector2(5,-3),p+Vector2(0,3)]),accent)
