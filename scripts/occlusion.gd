class_name P17Occlusion
extends RefCounted
## Lia and the drones stay readable behind tall scenery.
##
## Depth sorting is kept as it is: a machine whose base is south of Lia still
## covers her. After the y-sorted pass, every actor whose sprite is mostly
## inside the bounds of something drawn later gets a translucent tinted copy
## on top: cyan for Lia, rose for drones. Pure presentation, no simulation.
const LIA_OFFICIAL := preload("res://scripts/lia_official.gd")
const ENEMIES := preload("res://scripts/enemy_art.gd")
## Halo colour around the silhouette, and the opacity of the sprite itself.
const LIA_HALO := Color(0.30, 1.0, 0.88, 0.62)
const ENEMY_HALO := Color(1.0, 0.36, 0.64, 0.62)
const BODY := Color(1.0, 1.0, 1.0, 0.82)
const HALO_OFFSETS: Array[Vector2] = [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]
## Fraction of the sprite that must be covered before the silhouette shows.
const THRESHOLD := 0.22
const GRID := Vector2i(5, 8)

static func lia_rect(pos: Vector2) -> Rect2:
	return Rect2(pos + Vector2(-17, -50), Vector2(34, 66))

static func drone_rect(pos: Vector2, boss: bool) -> Rect2:
	if boss: return Rect2(pos + Vector2(-40, -58), Vector2(80, 86))
	return Rect2(pos + Vector2(-20, -30), Vector2(40, 44))

## Share of the actor rectangle inside any cover rectangle, sampled on a grid.
static func hidden_fraction(actor: Rect2, covers: Array[Rect2]) -> float:
	if covers.is_empty(): return 0.0
	var hits := 0
	for gy in GRID.y:
		for gx in GRID.x:
			var point := actor.position + actor.size * Vector2((gx + 0.5) / GRID.x, (gy + 0.5) / GRID.y)
			for cover in covers:
				if cover.has_point(point):
					hits += 1
					break
	return float(hits) / float(GRID.x * GRID.y)

## Low pieces (barrels, loose items, curbs) never hide a body; ignore them.
const MIN_COVER_HEIGHT := 40.0

## Covers drawn after the actor (deeper y) that overlap its sprite.
static func covers_for(actor: Rect2, actor_y: float, scenery: Array[Dictionary]) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for item in scenery:
		var y: float = item.y
		var bounds: Rect2 = item.bounds
		if y > actor_y and bounds.size.y >= MIN_COVER_HEIGHT and bounds.intersects(actor): result.append(bounds)
	return result

static func is_hidden(actor: Rect2, actor_y: float, scenery: Array[Dictionary]) -> bool:
	return hidden_fraction(actor, covers_for(actor, actor_y, scenery)) >= THRESHOLD

## A coloured halo (the sprite shifted 2 px each way, tinted) under a
## near-opaque copy: readable on teal machines and dark walls alike.
static func _silhouette(canvas: Node2D, texture: Texture2D, rect: Rect2, region: Rect2, halo: Color) -> void:
	for offset in HALO_OFFSETS:
		canvas.draw_texture_rect_region(texture, Rect2(rect.position + offset, rect.size), region, halo)
	canvas.draw_texture_rect_region(texture, rect, region, BODY)

static func draw_lia_ghost(canvas: Node2D, pos: Vector2, aim: Vector2, time: float, moving: bool, action: String) -> void:
	var origin := pos.round()
	if action == "repair":
		var frame := LIA_OFFICIAL.frame_for(aim, time, moving, action)
		var rect: Rect2 = frame.rect
		rect.position += origin
		_silhouette(canvas, frame.texture, rect, frame.region, LIA_HALO)
		return
	var pose := LIA_OFFICIAL.held_pose(aim, time, moving)
	var part: Dictionary = pose.parts[0]
	var rect: Rect2 = part.rect
	rect.position += origin
	_silhouette(canvas, part.texture, rect, part.region, LIA_HALO)

static func draw_drone_ghost(canvas: Node2D, view: Dictionary, fallback_time: float) -> void:
	ENEMIES.prepare()
	var time: float = view.get("anim_time", fallback_time)
	var frame := ENEMIES.frame_for(view, time)
	var kind: String = view.get("kind", "scout")
	var boss := kind == "boss"
	var origin: Vector2 = Vector2(view.pos).round()
	var foot := 29.0 if boss else 14.0
	var bob := sin(time * (7 if kind == "scout" else 5)) * (1.5 if kind == "scout" else .35)
	var offset := origin + Vector2(0, foot - (4.0 if kind == "scout" else 0.0) + bob)
	var rect := Rect2(frame.rect[0], frame.rect[1], frame.rect[2], frame.rect[3])
	var region := Rect2(frame.region[0], frame.region[1], frame.region[2], frame.region[3])
	var texture: Texture2D = ENEMIES._textures[kind]
	_silhouette(canvas, texture, Rect2(rect.position + offset, rect.size), region, ENEMY_HALO)
