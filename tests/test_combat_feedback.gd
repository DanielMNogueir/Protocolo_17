extends SceneTree
## The live Residues firing path must feed the recoil animation like Water.
const Residues = preload("res://scripts/residue_scenario.gd")
const HUD = preload("res://scripts/field_hud.gd")
var failures := 0

class SilentSound extends Node:
	func play_sfx(_id: String) -> void: pass

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var scene := Residues.new()
	var sound := SilentSound.new()
	scene.sound = sound
	var enemy := {"id": 0, "kind": "scout", "pos": Vector2(640, 480), "look_dir": Vector2.LEFT,
		"hp": 4, "max_hp": 8, "boss": false, "shot_cd": 0.0, "hit_cd": 0.0}
	scene._drone_attack(enemy)
	var view: Dictionary = scene._enemy_view(enemy)
	check(view.get("attack_age", 99.0) == 0.0, "A real enemy shot starts recoil")
	check(not scene.bullets.is_empty() and scene.bullets[0].hostile, "A shot produces the hostile pulse")
	enemy.attack_age = 0.2
	view = scene._enemy_view(enemy)
	check(view.attack_age == 0.2, "Recoil decays instead of sticking")
	check(view.max_hp == 8 and view.hp == 4, "Common health renderer receives the live ratio")
	for size in [Vector2(960, 540), Vector2(1440, 810)]:
		var objective := HUD.mission_rect(size.x)
		var radar := HUD.radar_rect(size)
		check(not objective.intersects(HUD.VITAL_RECT), "Health and objective do not overlap")
		check(not objective.intersects(HUD.PAUSE_BUTTON), "Objective clears pause control")
		check(not radar.intersects(Rect2(size * 0.5 - Vector2(140, 110), Vector2(280, 220))), "Minimap leaves combat center clear")
		check(HUD.VITAL_RECT.size.y < 70 and objective.size.y <= 80, "Combat headers stay compact")
	scene.free()
	sound.free()
	print("COMBAT_FEEDBACK_OK" if failures == 0 else "COMBAT_FEEDBACK_FAILED")
	quit(0 if failures == 0 else 1)
