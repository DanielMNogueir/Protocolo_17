extends CharacterBody2D

@export var speed: float = 220.0

const SPRITE_BASE_POSITION := Vector2(0, -40)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_direction := "down"
var movement_bob_phase := 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	animated_sprite.position = SPRITE_BASE_POSITION
	_create_input_actions()
	_create_animations()
	_play_animation("idle_down")


func reset_for_new_mission(start_position: Vector2) -> void:
	global_position = start_position
	velocity = Vector2.ZERO
	last_direction = "down"
	movement_bob_phase = 0.0
	set_meta("weapon_unlocked", false)
	animated_sprite.position = SPRITE_BASE_POSITION
	_play_animation("idle_down")


func _physics_process(delta: float) -> void:
	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = input_direction * speed
	move_and_slide()
	z_index = int(global_position.y)
	_update_animation(input_direction)
	_update_movement_visual(delta, input_direction)


func _update_animation(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		if abs(direction.x) > abs(direction.y):
			last_direction = "right" if direction.x > 0.0 else "left"
		else:
			last_direction = "down" if direction.y > 0.0 else "up"

	var has_weapon := bool(get_meta("weapon_unlocked", false))
	var movement_state := "walk" if direction != Vector2.ZERO else "idle"
	var animation_prefix := "armed_" if has_weapon else ""
	_play_animation(animation_prefix + movement_state + "_" + last_direction)


func _update_movement_visual(delta: float, direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		movement_bob_phase = 0.0
		animated_sprite.position = SPRITE_BASE_POSITION
		return

	var has_weapon := bool(get_meta("weapon_unlocked", false))
	var bob_speed := 11.0 if has_weapon else 13.0
	var bob_height := 2.0 if has_weapon else 0.8
	movement_bob_phase += delta * bob_speed
	animated_sprite.position = SPRITE_BASE_POSITION + Vector2(0, sin(movement_bob_phase) * bob_height)

func _play_animation(animation_name: String) -> void:
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)


func _create_animations() -> void:
	var movement_texture: Texture2D = load("res://assets/lia_movimento.png")
	var action_texture: Texture2D = load("res://assets/lia_acoes.png")
	var armed_action_texture: Texture2D = load("res://assets/lia_acoes_armada_v2.png")
	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	var direction_rows := {
		"down": 0,
		"left": 1,
		"right": 2,
		"up": 3,
	}
	var direction_columns := {
		"down": 0,
		"left": 1,
		"right": 2,
		"up": 3,
	}

	for direction: String in direction_rows:
		var walk_name := "walk_" + direction
		frames.add_animation(walk_name)
		frames.set_animation_speed(walk_name, 8.0)
		frames.set_animation_loop(walk_name, true)
		for column in range(4):
			frames.add_frame(
				walk_name,
				_create_atlas_frame(movement_texture, column, direction_rows[direction])
			)

		var idle_name := "idle_" + direction
		frames.add_animation(idle_name)
		frames.set_animation_speed(idle_name, 1.0)
		frames.set_animation_loop(idle_name, false)
		frames.add_frame(
			idle_name,
			_create_atlas_frame(action_texture, direction_columns[direction], 0)
		)

		# Row 1 of lia_acoes already contains Lia holding the pulse weapon.
		var armed_frame := _create_atlas_frame(armed_action_texture, direction_columns[direction], 1)
		var armed_idle_name := "armed_idle_" + direction
		frames.add_animation(armed_idle_name)
		frames.set_animation_speed(armed_idle_name, 1.0)
		frames.set_animation_loop(armed_idle_name, false)
		frames.add_frame(armed_idle_name, armed_frame)

		var armed_walk_name := "armed_walk_" + direction
		frames.add_animation(armed_walk_name)
		frames.set_animation_speed(armed_walk_name, 4.0)
		frames.set_animation_loop(armed_walk_name, true)
		frames.add_frame(
			armed_walk_name,
			_create_atlas_frame(armed_action_texture, direction_columns[direction], 1)
		)

	animated_sprite.sprite_frames = frames


func _create_atlas_frame(texture: Texture2D, column: int, row: int) -> AtlasTexture:
	var atlas_frame := AtlasTexture.new()
	atlas_frame.atlas = texture
	atlas_frame.region = Rect2(column * 128, row * 128, 128, 128)
	return atlas_frame


func _create_input_actions() -> void:
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("move_up", [KEY_W, KEY_UP])
	_add_action("move_down", [KEY_S, KEY_DOWN])


func _add_action(action_name: StringName, keycodes: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	if not InputMap.action_get_events(action_name).is_empty():
		return

	for keycode in keycodes:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action_name, event)
