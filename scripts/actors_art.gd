class_name P17Actors
extends RefCounted
## Official Lia sprites; existing procedural enemy art and radio portrait retained.
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
	var origin: Vector2 = Vector2(enemy.get("pos", Vector2.ZERO)).round()
	var kind: String = str(enemy.get("kind", "scout"))
	var direction: Vector2 = enemy.get("aim", Vector2.DOWN)
	if direction.length_squared() < 0.01:
		direction = Vector2.DOWN
	direction = direction.normalized()
	var warning_value: Variant = enemy.get("warning", 0.0)
	var warning := bool(warning_value) if warning_value is bool else float(warning_value) > 0.0
	var bob := int(round(sin(time * 4.0 + origin.x * 0.02) * 2.0))
	var body := origin + Vector2(0, -3 + bob)
	if kind == "boss":
		_draw_boss(canvas, body, origin, direction, time, warning, enemy)
		return
	_p(canvas, origin, -14, 10, 28, 5, Color(0.02, 0.055, 0.07, 0.38))
	_p(canvas, origin, -10, 8, 20, 9, Color(0.02, 0.055, 0.07, 0.25))
	var shell := TEAL if kind == "scout" else (Color("987b4f") if kind == "sentry" else Color("a3654b"))
	var light := TEAL_LIGHT if kind == "scout" else (Color("d2b477") if kind == "sentry" else Color("d8996a"))
	# Rotor outriggers and motor pods retain clear distinct enemy silhouettes.
	if kind == "scout":
		_p(canvas, body, -21, -5, 42, 4, INK)
		_p(canvas, body, -19, -4, 38, 2, STEEL)
		for side in [-1, 1]:
			var rotor := body + Vector2(side * 18, -5)
			_p(canvas, rotor, -5, -2, 10, 7, INK)
			_p(canvas, rotor, -3, -2, 6, 5, STEEL_DARK)
			_p(canvas, rotor, -2, -1, 3, 2, STEEL_LIGHT)
			var blade := 1 if int(time * 24.0) % 2 == 0 else 0
			_p(canvas, rotor, -7, -4, 14, 2, STEEL if blade else BLUE)
			_p(canvas, rotor, -1, -7 + blade, 2, 8 - blade, STEEL_LIGHT)
	elif kind == "sentry":
		for side in [-1, 1]:
			_p(canvas, body, side * 14 - 4, -9, 8, 23, INK)
			_p(canvas, body, side * 14 - 3, -8, 6, 19, STEEL_DARK)
			for vent in range(4):
				_p(canvas, body, side * 14 - 3, -6 + vent * 4, 5, 2, STEEL)
	else:
		for side in [-1, 1]:
			_p(canvas, body, side * 16 - 5, -8, 10, 24, INK)
			_p(canvas, body, side * 16 - 4, -7, 8, 19, STEEL_DARK)
			_p(canvas, body, side * 16 - 3, -7, 3, 19, STEEL)
			for tread in range(4):
				_p(canvas, body, side * 16 - 4, -5 + tread * 5, 8, 2, INK)
	_p(canvas, body, -11, -14, 22, 26, INK)
	_p(canvas, body, -14, -9, 28, 16, INK)
	_p(canvas, body, -10, -13, 20, 23, STEEL_DARK)
	_p(canvas, body, -13, -8, 26, 13, shell)
	_p(canvas, body, -9, -13, 18, 18, shell)
	_p(canvas, body, -9, -13, 16, 3, light)
	_p(canvas, body, -12, -8, 3, 10, light)
	_p(canvas, body, 9, -7, 3, 12, STEEL_DARK)
	_p(canvas, body, -7, 6, 14, 4, INK)
	_p(canvas, body, -5, 7, 10, 2, TEAL_LIGHT)
	for bolt in [Vector2(-8, -9), Vector2(7, -9), Vector2(-10, 2), Vector2(9, 2)]:
		_p(canvas, body + bolt, 0, 0, 2, 2, STEEL_LIGHT)
	# Eye shutter is the universal corrupted component.
	_p(canvas, body, -7, -7, 14, 9, INK)
	_p(canvas, body, -6, -6, 12, 6, TOXIC_DARK)
	_p(canvas, body, -5, -5, 10, 3, GOLD_LIGHT if warning else TOXIC)
	_p(canvas, body, -2, -5, 4, 2, Color("ffe5bb") if warning else Color("ffc1d8"))
	if kind == "sentry":
		var muzzle := body + direction * 21.0
		_bar(canvas, body + Vector2(0, 3), muzzle, 9.0, INK)
		_bar(canvas, body + direction * 4.0, muzzle - direction * 2.0, 5.0, STEEL)
		_bar(canvas, muzzle - direction * 4.0, muzzle, 5.0, GOLD_LIGHT if warning else TOXIC_DARK)
	elif kind == "rammer":
		_p(canvas, body, -14, 6, 28, 8, INK)
		_p(canvas, body, -13, 7, 26, 5, STEEL)
		for tooth in range(5):
			_p(canvas, body, -11 + tooth * 5, 8, 3, 6, GOLD if tooth % 2 == 0 else STEEL_DARK)
	else:
		_p(canvas, body, -2, 7, 4, 9, INK)
		_p(canvas, body, -1, 8, 2, 6, STEEL_LIGHT)
	if warning:
		_warning_corners(canvas, origin, 24.0, time)


static func _draw_boss(canvas: Node2D, body: Vector2, origin: Vector2, aim: Vector2, time: float, warning: bool, enemy: Dictionary) -> void:
	_p(canvas, origin, -38, 23, 76, 12, Color(0.02, 0.05, 0.065, 0.40))
	_p(canvas, origin, -29, 17, 58, 25, Color(0.02, 0.05, 0.065, 0.25))
	# The reclamation engine: four piston legs, armored manifolds and twin cannons.
	for side in [-1, 1]:
		for row in [-1, 1]:
			var leg := body + Vector2(side * 31, row * 22)
			_p(canvas, leg, -12, -8, 24, 16, INK)
			_p(canvas, leg, -10, -6, 20, 12, STEEL_DARK)
			_p(canvas, leg, -9, -6, 17, 3, STEEL_LIGHT)
			_p(canvas, leg, -8, -2, 15, 7, STEEL)
			for slit in range(3):
				_p(canvas, leg, -7 + slit * 6, -1, 3, 7, INK)
		var pod := body + Vector2(side * 30, -6)
		_p(canvas, pod, -11, -15, 22, 35, INK)
		_p(canvas, pod, -9, -14, 18, 30, TEAL_DARK)
		_p(canvas, pod, -8, -13, 5, 27, TEAL)
		_p(canvas, pod, -8, -13, 15, 3, TEAL_LIGHT)
		for slot in range(4):
			_p(canvas, pod, -4, -5 + slot * 4, 10, 2, INK)
		_p(canvas, pod, -5, -11, 10, 4, GOLD)
		var muzzle := pod + aim * 22.0
		_bar(canvas, pod + Vector2(0, 8), muzzle, 13.0, INK)
		_bar(canvas, pod + Vector2(0, 8), muzzle - aim * 2.0, 8.0, STEEL)
		_bar(canvas, muzzle - aim * 5.0, muzzle, 8.0, GOLD_LIGHT if warning else TOXIC_DARK)
	_p(canvas, body, -23, -32, 46, 65, INK)
	_p(canvas, body, -28, -25, 56, 49, INK)
	_p(canvas, body, -22, -31, 44, 59, STEEL_DARK)
	_p(canvas, body, -26, -23, 51, 44, TEAL_DARK)
	_p(canvas, body, -20, -29, 40, 53, TEAL)
	_p(canvas, body, -20, -29, 36, 5, TEAL_LIGHT)
	_p(canvas, body, -24, -22, 5, 39, TEAL_LIGHT)
	_p(canvas, body, 17, -23, 7, 44, Color("204545"))
	_p(canvas, body, -16, -23, 30, 6, INK)
	for vent in range(5):
		_p(canvas, body, -14 + vent * 6, -22, 3, 4, STEEL)
	# Segmented copper coolant piping around the exposed magenta control core.
	_p(canvas, body, -18, -11, 36, 31, GOLD_DARK)
	_p(canvas, body, -16, -13, 32, 35, GOLD_DARK)
	_p(canvas, body, -16, -12, 30, 3, GOLD)
	_p(canvas, body, -17, -10, 3, 26, GOLD)
	_p(canvas, body, -14, -9, 28, 27, INK)
	_p(canvas, body, -11, -7, 22, 24, TOXIC_DARK)
	_p(canvas, body, -9, -9, 18, 28, TOXIC_DARK)
	var core_light := GOLD_LIGHT if warning else TOXIC
	_p(canvas, body, -8, -5, 16, 18, core_light)
	_p(canvas, body, -5, -8, 10, 24, core_light)
	_p(canvas, body, -5, -3, 10, 13, Color("ffc2d4"))
	_p(canvas, body, -2, -1, 4, 9, Color("fff0dd"))
	for rib in [-1, 1]:
		_p(canvas, body, rib * 10 - 2, -7, 4, 5, STEEL_DARK)
		_p(canvas, body, rib * 10 - 2, 9, 4, 5, STEEL_DARK)
	for bolt in [Vector2(-18, -20), Vector2(16, -20), Vector2(-20, 22), Vector2(18, 22)]:
		_p(canvas, body + bolt, 0, 0, 3, 3, STEEL_LIGHT)
	_p(canvas, body, -12, 25, 24, 5, INK)
	for stripe in range(4):
		_p(canvas, body, -10 + stripe * 6, 26, 3, 3, GOLD)
	# Damaged armor exposes progressively more faults, without changing collision.
	var health_ratio := float(enemy.get("hp", 100.0)) / maxf(1.0, float(enemy.get("max_hp", 100.0)))
	if health_ratio < 0.5:
		_p(canvas, body, 9, -22, 2, 7, INK)
		_p(canvas, body, 7, -16, 3, 5, INK)
		if int(time * 9.0) % 3 == 0:
			_p(canvas, body, 6, -19, 3, 3, GOLD_LIGHT)
	if warning:
		_warning_corners(canvas, origin, 48.0, time)


static func _warning_corners(canvas: Node2D, origin: Vector2, radius: float, time: float) -> void:
	var color := Color("efb46a") if sin(time * 15.0) > 0.0 else Color("b77358")
	for x in [-1, 1]:
		for y in [-1, 1]:
			var corner := origin + Vector2(x, y) * radius
			_bar(canvas, corner, corner - Vector2(x * 8, 0), 2.0, color)
			_bar(canvas, corner, corner - Vector2(0, y * 8), 2.0, color)


static func _p(canvas: Node2D, pos: Vector2, x: int, y: int, width: int, height: int, color: Color) -> void:
	canvas.draw_rect(Rect2(pos + Vector2(x, y), Vector2(width, height)), color)


static func _bar(canvas: Node2D, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var normal := (to - from).normalized().orthogonal() * width * 0.5
	if normal.length_squared() < 0.001:
		return
	canvas.draw_colored_polygon(PackedVector2Array([
		(from + normal).round(), (to + normal).round(),
		(to - normal).round(), (from - normal).round()]), color)
