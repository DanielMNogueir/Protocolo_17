extends RefCounted
## Shared gamepad input for the prologue and all four districts.

const STICK_DEADZONE := 0.24
const MENU_DEADZONE := 0.55
const TRIGGER_THRESHOLD := 0.35
const HINTS := {"E": "A", "Q": "RB", "SHIFT": "LB", "M": "VIEW", "ESC": "MENU", "ENTER": "A", "TAB": "Y"}

static var active := false
static var device := 0

var _menu_axis := 0
var _focus := ""
var _drawn_menu := ""
var _block_interaction := false


static func hint(label: String) -> String:
	return HINTS.get(label, label) if active else label


func movement(key_pressed: Callable) -> Vector2:
	var keys := Vector2(
		float(key_pressed.call(KEY_D) or key_pressed.call(KEY_RIGHT))
		- float(key_pressed.call(KEY_A) or key_pressed.call(KEY_LEFT)),
		float(key_pressed.call(KEY_S) or key_pressed.call(KEY_DOWN))
		- float(key_pressed.call(KEY_W) or key_pressed.call(KEY_UP)))
	return keys.normalized() if keys != Vector2.ZERO else (_stick(JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y) if active else Vector2.ZERO)


func aim_target(origin: Vector2, facing: Vector2, mouse_target: Vector2) -> Vector2:
	if not active:
		return mouse_target
	var direction := _stick(JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y)
	return origin + (facing if direction == Vector2.ZERO else direction.normalized()) * 150.0


func reticle(mouse: Vector2, origin: Vector2, facing: Vector2) -> Vector2:
	return origin + facing * 72.0 if active else mouse


func firing() -> bool:
	return active and Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) >= TRIGGER_THRESHOLD


func interacting() -> bool:
	if not active or not Input.is_joy_button_pressed(device, JOY_BUTTON_A):
		_block_interaction = false
		return false
	return not _block_interaction


func _stick(x: JoyAxis, y: JoyAxis) -> Vector2:
	var raw := Vector2(Input.get_joy_axis(device, x), Input.get_joy_axis(device, y))
	var magnitude := raw.length()
	if magnitude <= STICK_DEADZONE:
		return Vector2.ZERO
	return raw / magnitude * remap(minf(magnitude, 1.0), STICK_DEADZONE, 1.0, 0.0, 1.0)


func key_for(event: InputEvent, menu: String, buttons: Array[Dictionary], action: Callable, confirm: Key = KEY_E) -> Key:
	if event is InputEventMouseButton or (event is InputEventMouseMotion and event.relative.length_squared() >= 1.0):
		active = false
		_focus = ""
		return KEY_NONE
	if event is InputEventKey and event.pressed and not event.echo:
		active = false
		_focus = ""
		return event.physical_keycode if event.physical_keycode else event.keycode
	var direction := 0
	if event is InputEventJoypadMotion:
		if absf(event.axis_value) > STICK_DEADZONE:
			active = true
			device = event.device
		if event.axis not in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
			return KEY_NONE
		# Crossing the threshold moves one slot. Return to center to move again.
		var axis_value: float = event.axis_value
		if absf(axis_value) < STICK_DEADZONE:
			if abs(_menu_axis) == event.axis + 1: _menu_axis = 0
			return KEY_NONE
		if absf(axis_value) < MENU_DEADZONE or _menu_axis != 0:
			return KEY_NONE
		direction = -1 if axis_value < 0.0 else 1
		_menu_axis = direction * (event.axis + 1)
	elif event is InputEventJoypadButton:
		if not event.pressed:
			if event.button_index == JOY_BUTTON_A and event.device == device:
				_block_interaction = false
			return KEY_NONE
		device = event.device
		active = true
		match event.button_index:
			JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_LEFT: direction = -1
			JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_RIGHT: direction = 1
			JOY_BUTTON_A:
				if not menu.is_empty():
					_block_interaction = true
					if _drawn_menu == menu:
						var index := _index(buttons)
						if index >= 0:
							_focus = ""
							action.call(buttons[index].id)
							return KEY_NONE
					return KEY_NONE
				if confirm != KEY_E: _block_interaction = true
				return confirm
			JOY_BUTTON_B, JOY_BUTTON_START: return KEY_ESCAPE
			JOY_BUTTON_BACK: return KEY_M
			JOY_BUTTON_Y: return KEY_TAB if menu.is_empty() else KEY_NONE
			JOY_BUTTON_LEFT_SHOULDER: return KEY_SHIFT
			JOY_BUTTON_RIGHT_SHOULDER: return KEY_Q
	else:
		return KEY_NONE
	if direction != 0 and not menu.is_empty() and _drawn_menu == menu and not buttons.is_empty():
		_focus = buttons[posmod(_index(buttons) + direction, buttons.size())].id
	return KEY_NONE


func _index(buttons: Array[Dictionary]) -> int:
	for index in buttons.size():
		if buttons[index].id == _focus:
			return index
	return 0 if not buttons.is_empty() else -1


func draw_focus(canvas: CanvasItem, menu: String, buttons: Array[Dictionary]) -> void:
	if menu != _drawn_menu:
		_focus = ""
		_drawn_menu = menu
	if not active or menu.is_empty():
		return
	var index := _index(buttons)
	if index >= 0:
		var bounds: Rect2 = buttons[index].rect
		canvas.draw_rect(bounds.grow(2.0), Color("f5cf78"), false, 2.0)
