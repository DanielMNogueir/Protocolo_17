class_name P17LiaAnimation
extends RefCounted
## Pose time only. The caller advances this alongside the active simulation tick.
## Facing is intentionally absent: turns preserve the current gait phase.

var elapsed: float = 0.0
var moving: bool = false


func advance(delta: float, velocity: Vector2, dashing: bool) -> void:
	if delta <= 0.0 or not is_finite(delta):
		return
	var next_moving: bool = velocity.length() > 5.0 or dashing
	if next_moving != moving:
		moving = next_moving
		elapsed = 0.0
		return
	elapsed += delta


func reset() -> void:
	elapsed = 0.0
	moving = false
