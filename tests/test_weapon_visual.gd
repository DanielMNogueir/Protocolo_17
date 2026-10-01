extends SceneTree
const Visual := preload("res://scripts/lia_official.gd")
const Directional := preload("res://scripts/lia_directional.gd")
const Actors := preload("res://scripts/actors_art.gd")
var checks := 0
var failures := 0

class Gallery extends Node2D:
 var action := "idle"
 var phase := 0.0
 func _draw() -> void:
  draw_rect(Rect2(0, 0, 960, 540), Color("112a33"))
  var title: String = {"idle": "REPOUSO", "walk": "CAMINHADA", "fire": "DISPARO", "blink": "PISCADA"}[action]
  draw_string(ThemeDB.fallback_font, Vector2(20, 24), "LIA / 24 DIREÇÕES / PASSOS DE 15° — " + title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
  for i in 24:
   var aim := Vector2.RIGHT.rotated(i * TAU / 24)
   var point := Vector2(80 + (i % 6) * 160, 102 + (i / 6) * 122)
   draw_set_transform(point, 0, Vector2.ONE * 1.55)
   draw_line(Vector2(-20, 18), Vector2(20, 18), Color("365760"), .5)
   Actors.draw_lia(self, Vector2.ZERO, aim, phase, action == "walk", false, false, "fire" if action == "fire" else "idle", .02 if action == "fire" else -1)
   if action == "fire":
    var muzzle: Vector2 = Visual.held_pose(aim, phase, false).muzzle
    draw_line(muzzle + aim * 10, muzzle + aim * 23, Color("618c93"), .5)
   draw_set_transform(Vector2.ZERO)
   draw_string(ThemeDB.fallback_font, point + Vector2(-12, 51), "%d°" % (i * 15), HORIZONTAL_ALIGNMENT_LEFT, -1, 11)

func _initialize() -> void:
 _run.call_deferred()

func check(condition: bool, message: String) -> void:
 checks += 1
 if not condition:
  failures += 1
  push_error(message)

func _snapshot(sim: RefCounted) -> String:
 return var_to_str([sim.pos, sim.velocity, sim.aim, sim.bullets, sim.enemies, sim.particles, sim.events, sim.hp, sim.max_hp, sim._fire_cd, sim.fire_interval, sim.shots, sim.pulse_damage, sim.pulse_speed, sim.dash_cd, sim.dash_time, sim.invuln, sim.repair, sim.stage, sim.restored, sim.state, sim.chosen, sim.kills, sim.elapsed])

func _run() -> void:
 check(Directional.DATA.directions == 24 and Directional.DATA.step_degrees == 15, "Twenty-four authored headings at fifteen-degree intervals")
 check(Visual.direction_index(Vector2.ZERO) == 6, "Zero aim retains front/down default")
 var total := 0
 for direction in 24:
  var aim := Vector2.RIGHT.rotated(deg_to_rad(direction * 15.0))
  for offset: float in [-7.49, 0.0, 7.49]:
   check(Visual.direction_index(aim.rotated(deg_to_rad(offset))) == direction, "Nearest heading throughout each 15-degree sector")
  check(Visual.direction_index(aim.rotated(deg_to_rad(7.51))) == (direction + 1) % 24, "Sector boundary advances and wraps at 360 degrees")
  for state in ["idle", "walk"]:
   var rows: Array = Directional.DATA[state][direction]
   check(rows.size() == (8 if state == "walk" else 2), "Every heading has full walk and idle/blink animation")
   var seen := {}
   for step in rows.size():
    var metadata: Dictionary = rows[step]
    var moving: bool = state == "walk"
    var time := (step + .01) / 18.0 if moving else (0.0 if step == 0 else 3.9)
    var pose := Visual.held_pose(aim, time, moving)
    check(pose.direction == direction and pose.frame == step, "Body and animation resolve the requested heading and phase")
    check(pose.parts.size() == 1, "Hands, rifle and complete character use a single sprite")
    var part: Dictionary = pose.parts[0]
    var image: Image = part.texture.get_image()
    var region: Rect2 = part.region
    check(Rect2(Vector2.ZERO, image.get_size()).encloses(region), "Atlas region is in bounds")
    check(image.get_pixel(0, 0).a == 0, "Background has real alpha")
    var frame := image.get_region(Rect2i(region))
    check(frame.get_used_rect().has_area(), "Pose has visible pixels")
    var digest := HashingContext.new()
    digest.start(HashingContext.HASH_SHA256)
    digest.update(frame.get_data())
    var signature := digest.finish().hex_encode()
    if moving: check(not seen.has(signature), "All eight gait images are distinct per heading")
    seen[signature] = true
    check(is_equal_approx(part.rect.end.y, 18), "Feet remain planted at the established ground baseline")
    check(is_equal_approx(pose.scale, Directional.DATA.scales.idle), "One global scale across all angles and phases")
    var muzzle: Vector2 = pose.muzzle
    check(muzzle.is_finite() and muzzle.length() < 60, "Finite emitter position local to each pose")
    var emitter := Vector2i(metadata.muzzle[0], metadata.muzzle[1])
    var found_cyan := false
    for dy in range(-5, 6):
     for dx in range(-5, 6):
      var p := emitter + Vector2i(dx, dy)
      if Rect2i(Vector2i.ZERO, image.get_size()).has_point(p):
       var c := image.get_pixelv(p)
       if c.a > .5 and c.g > .65 and c.b > .65 and c.b > c.r * 1.35: found_cyan = true
    check(found_cyan, "Muzzle anchor lies next to the authored cyan emitter")
    if moving:
     check(Visual.held_pose(aim, time + 8.0 / 18.0, true).frame == step, "Walking cycle retains cadence and wraps correctly")
     check(Visual.held_pose(aim.rotated(TAU / 24), time, true).frame == step, "Turning does not reset the gait")
    total += 1
  for age: float in [-1, 0, .05, .1, .2]:
   var recoil := Actors.WEAPON.recoil_at(age)
   check(Visual.recoil_point(Vector2(10, 18), aim, recoil).is_equal_approx(Vector2(10, 18)), "Recoil leaves the ground fixed")
 check(total == 240, "All 192 walking and 48 idle/blink source frames validated")
 for i in 720:
  var angle := deg_to_rad(i * .5)
  var selected := Visual.direction_index(Vector2.from_angle(angle)) * TAU / 24
  check(absf(angle_difference(angle, selected)) <= deg_to_rad(7.501), "Nearest visual heading never differs by more than half a sector")
 check(Directional.idle_frame(3.839) == 0 and Directional.idle_frame(3.841) == 1 and Directional.idle_frame(4.001) == 0, "Brief blink timing preserved")
 if DisplayServer.get_name() != "headless":
  root.content_scale_size = Vector2i(960, 540)
  root.size = Vector2i(1440, 810)
  var gallery := Gallery.new()
  root.add_child(gallery)
  for action in ["idle", "walk", "fire", "blink"]:
   gallery.action = action
   gallery.phase = 3.90 if action == "blink" else .13
   gallery.queue_redraw()
   await process_frame
   await RenderingServer.frame_post_draw
   check(root.get_texture().get_image().save_png("res://captures/lia_24_" + action + ".png") == OK, "Directional gallery saved")
  # Eight phases on the same 24-heading gallery for motion review.
  for step in 8:
   gallery.action = "walk"
   gallery.phase = (step + .01) / 18.0
   gallery.queue_redraw()
   await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://captures/lia_24_step_%d.png" % step)
  gallery.queue_free()
  await process_frame
  var game: Node2D = load("res://scenes/main.tscn").instantiate()
  root.add_child(game)
  await process_frame
  game.set_process(false)
  game.sound.set_muted(true)
  for player in game.sound.get_children():
   if player is AudioStreamPlayer: player.stop()
  game.sim.start()
  game.sim.pos = Vector2(800, 1420)
  game.mode = "play"
  game.camera_pos = game.sim.pos
  game._clamp_camera()
  for direction in 24:
   game.sim.aim = Vector2.from_angle(deg_to_rad(direction * 15.0))
   game.lia_animation.elapsed = .13
   game.lia_animation.moving = true
   var before := _snapshot(game.sim)
   game.queue_redraw()
   await process_frame
   await RenderingServer.frame_post_draw
   check(before == _snapshot(game.sim), "Real scene drawing preserves all combat and progression state")
  root.get_texture().get_image().save_png("res://captures/lia_24_game.png")
  game.free()
  game = null
  for cleanup in range(5): await process_frame
 print("WEAPON_VISUAL_", "OK" if failures == 0 else "FAILED", ": ", checks, " checks; 24 headings; ", failures, " failures")
 quit(0 if failures == 0 else 1)
