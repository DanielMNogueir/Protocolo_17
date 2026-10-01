class_name P17Actors
extends RefCounted
## Illustrated Lia and enemies; procedural radio portrait retained.
## Positions identify the collision centre, with character feet sixteen pixels below.

const INK := Color("10202a")
const DEEP := Color("182e40")
const NAVY := Color("294d63")
const BLUE := Color("477084")
const TEAL_DARK := Color("185253")
const TEAL := Color("287e7b")
const TEAL_LIGHT := Color("58b5a2")
const CYAN := Color("a0e7cb")
const SKIN_DARK := Color("8c5545")
const SKIN := Color("c18b64")
const SKIN_LIGHT := Color("e0ab79")
const GOLD_DARK := Color("8e663b")
const GOLD := Color("cca252")
const GOLD_LIGHT := Color("efd387")
const LEATHER := Color("775749")
const STEEL_DARK := Color("344b55")
const STEEL := Color("698080")
const STEEL_LIGHT := Color("a1b5ac")
const TOXIC := Color("e86ea0")
const TOXIC_DARK := Color("934064")
const LIA_OFFICIAL := preload("res://scripts/lia_official.gd")
const WEAPON := preload("res://scripts/weapon_visual.gd")
const ENEMIES := preload("res://scripts/enemy_art.gd")


static func draw_lia(canvas: Node2D, pos: Vector2, aim: Vector2, time: float, moving: bool, hurt: bool, dashing: bool, action: String = "idle", shot_age: float = -1.0) -> void:
	if action == "repair" and not dashing:
		LIA_OFFICIAL.draw(canvas, pos, aim, time, moving, hurt, false, action)
		return
	# Hands, forearms and weapon come from ONE official held pose at every angle.
	var recoil := WEAPON.recoil_at(shot_age) if not dashing else 0.0
	var muzzle := LIA_OFFICIAL.draw_held(canvas, pos, aim, time, moving, hurt, dashing, recoil)
	if not dashing:
		WEAPON.draw_flash(canvas, muzzle, aim, shot_age)


static func draw_lia_portrait(canvas: Node2D, pos: Vector2, aim: Vector2, time: float, moving: bool, hurt: bool, dashing: bool) -> void:
	var origin := pos.round()
	var direction := aim.normalized() if aim.length_squared() > 0.01 else Vector2.DOWN
	var back := direction.y < -0.40
	var side := 1 if direction.x >= 0.0 else -1
	var stride := int(round(sin(time * 14.0) * 3.0)) if moving else 0
	var bob := -1 if moving and sin(time * 28.0) > 0.1 else 0
	var body := origin + Vector2(0, bob)
	# A stepped contact shadow grounds the sprite without a smooth ellipse.
	_p(canvas, origin, -12, 12, 24, 6, Color(0.035, 0.07, 0.08, 0.35))
	_p(canvas, origin, -8, 10, 16, 10, Color(0.035, 0.07, 0.08, 0.27))
	if dashing:
		for echo in range(3, 0, -1):
			var trail := body - direction * float(echo * 8)
			_p(canvas, trail, -9, -12, 18, 27, Color(0.34, 0.76, 0.68, 0.09 * float(4 - echo)))
	# Boots, articulated trouser legs, seams and kneepads.
	for leg in [-1, 1]:
		var lx := -8 if leg < 0 else 1
		var foot: int = stride * int(leg)
		_p(canvas, origin, lx - 1, 3 + foot, 9, 14, INK)
		_p(canvas, origin, lx, 3 + foot, 7, 10, DEEP)
		_p(canvas, origin, lx, 4 + foot, 3, 6, NAVY)
		_p(canvas, origin, lx, 7 + foot, 6, 4, BLUE)
		_p(canvas, origin, lx + 1, 7 + foot, 4, 1, STEEL_LIGHT)
		_p(canvas, origin, lx - 1, 13 + foot, 9, 5, LEATHER)
		_p(canvas, origin, lx, 13 + foot, 6, 2, Color("ab8260"))
		_p(canvas, origin, lx - 1, 17 + foot, 9, 2, INK)
	# Backpack is visible behind the near shoulder in every direction.
	_p(canvas, body, -11, -12, 21, 17, INK)
	_p(canvas, body, -10, -11, 19, 14, GOLD_DARK)
	_p(canvas, body, -9, -11, 2, 12, GOLD)
	# Suit silhouette, upper-body plates and harness.
	_p(canvas, body, -9, -14, 18, 21, INK)
	_p(canvas, body, -8, -13, 16, 19, DEEP)
	_p(canvas, body, -7, -12, 10, 17, NAVY)
	_p(canvas, body, -6, -12, 5, 8, BLUE)
	_p(canvas, body, -13, -13, 8, 8, INK)
	_p(canvas, body, 5, -13, 8, 8, INK)
	_p(canvas, body, -12, -13, 7, 6, TEAL)
	_p(canvas, body, 5, -13, 7, 6, TEAL_DARK)
	_p(canvas, body, -11, -13, 6, 2, TEAL_LIGHT)
	_p(canvas, body, 6, -13, 5, 2, TEAL_LIGHT)
	_p(canvas, body, -11, -9, 1, 1, STEEL_LIGHT)
	_p(canvas, body, 10, -9, 1, 1, STEEL_LIGHT)
	_p(canvas, body, -6, -12, 2, 16, GOLD)
	_p(canvas, body, 4, -12, 2, 16, GOLD_DARK)
	_p(canvas, body, -7, -3, 14, 2, GOLD)
	_p(canvas, body, -9, 4, 18, 3, LEATHER)
	_p(canvas, body, -2, 4, 4, 3, GOLD_LIGHT)
	_p(canvas, body, -1, 5, 2, 1, INK)
	_p(canvas, body, -10, 3, 4, 5, GOLD_DARK)
	_p(canvas, body, 7, 3, 4, 5, GOLD)
	if back:
		_p(canvas, body, -6, -10, 12, 13, INK)
		_p(canvas, body, -5, -9, 10, 11, GOLD_DARK)
		_p(canvas, body, -4, -8, 8, 8, TEAL_DARK)
		_p(canvas, body, -4, -9, 8, 2, GOLD)
		# Three little arrows form Lia's recycling patch.
		_p(canvas, body, -1, -7, 3, 1, CYAN)
		_p(canvas, body, 1, -6, 2, 3, CYAN)
		_p(canvas, body, -2, -3, 4, 1, CYAN)
		_p(canvas, body, -3, -5, 2, 2, CYAN)
	# Neck and face; eyes shift towards the aim direction.
	_p(canvas, body, -3, -17, 6, 5, SKIN_DARK)
	_p(canvas, body, -8, -27, 16, 13, INK)
	_p(canvas, body, -7, -25, 14, 10, SKIN_DARK)
	if not back:
		_p(canvas, body, -5, -24, 11, 8, SKIN)
		_p(canvas, body, -4, -23, 8, 4, SKIN_LIGHT)
		var glance := side if absf(direction.x) > 0.3 else 0
		_p(canvas, body, -4 + glance, -21, 2, 2, INK)
		_p(canvas, body, 2 + glance, -21, 2, 2, INK)
		_p(canvas, body, 0 + glance, -18, 2, 1, SKIN_DARK)
		_p(canvas, body, -2, -15, 5, 1, SKIN_LIGHT)
	# High teal ponytail, copper clasp and asymmetrical swept fringe.
	var hair_sway := int(round(sin(time * (10.0 if moving else 2.0)) * 1.5))
	_p(canvas, body, -8, -29, 15, 7, INK)
	_p(canvas, body, -7, -28, 13, 5, TEAL_DARK)
	_p(canvas, body, -6, -28, 9, 2, TEAL_LIGHT)
	_p(canvas, body, -7, -26, 11, 3, TEAL)
	_p(canvas, body, -7, -24, 4, 5, TEAL)
	_p(canvas, body, -6, -24, 2, 4, TEAL_LIGHT)
	_p(canvas, body, 4, -25, 3, 4, TEAL_DARK)
	_p(canvas, body, 3 + hair_sway, -32, 8, 5, INK)
	_p(canvas, body, 4 + hair_sway, -31, 6, 4, TEAL)
	_p(canvas, body, 8 + hair_sway, -29, 5, 10, INK)
	_p(canvas, body, 8 + hair_sway, -28, 4, 8, TEAL)
	_p(canvas, body, 9 + hair_sway, -27, 2, 5, TEAL_LIGHT)
	_p(canvas, body, 9 + hair_sway, -20, 3, 4, TEAL_DARK)
	_p(canvas, body, 4, -29, 3, 2, GOLD)
	if back:
		_p(canvas, body, -6, -23, 12, 6, TEAL_DARK)
		_p(canvas, body, -5, -23, 3, 5, TEAL)
	# Far arm hangs naturally, while near arm supports a separate pulse tool.
	var arm_x := -12 if side > 0 else 9
	_p(canvas, body, arm_x, -6, 4, 10, INK)
	_p(canvas, body, arm_x + 1, -6, 2, 5, NAVY)
	_p(canvas, body, arm_x, 0, 4, 4, SKIN)
	_p(canvas, body, arm_x, 1, 4, 2, DEEP)
	var grip := body + Vector2(side * 8, -3)
	var muzzle := grip + direction * 18.0
	_bar(canvas, grip, muzzle, 8.0, INK)
	_bar(canvas, grip + direction * 2.0, muzzle - direction * 2.0, 5.0, STEEL_DARK)
	_bar(canvas, grip + direction * 4.0 + Vector2(-1, -1), muzzle - direction * 4.0 + Vector2(-1, -1), 2.0, STEEL_LIGHT)
	_bar(canvas, muzzle - direction * 4.0, muzzle, 4.0, TEAL_LIGHT)
	_p(canvas, grip, -2, -2, 5, 5, SKIN)
	_p(canvas, grip, -2, 0, 5, 2, DEEP)
	if hurt:
		_p(canvas, body, -6, -12, 12, 2, Color("fff1df"))
		_p(canvas, body, -11, -12, 4, 4, Color("fff1df"))
		_p(canvas, body, 6, -12, 4, 4, Color("fff1df"))


static func draw_drone(canvas: Node2D, enemy: Dictionary, time: float) -> void:
	ENEMIES.draw(canvas, enemy, time)


static func _p(canvas: Node2D, pos: Vector2, x: int, y: int, width: int, height: int, color: Color) -> void:
	canvas.draw_rect(Rect2(pos + Vector2(x, y), Vector2(width, height)), color)


static func _bar(canvas: Node2D, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var normal := (to - from).normalized().orthogonal() * width * 0.5
	if normal.length_squared() < 0.001:
		return
	canvas.draw_colored_polygon(PackedVector2Array([
		(from + normal).round(), (to + normal).round(),
		(to - normal).round(), (from - normal).round()]), color)
