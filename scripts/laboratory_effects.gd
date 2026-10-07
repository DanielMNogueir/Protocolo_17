class_name P17LaboratoryEffects
extends Node
## One synchronized render surface supplies the floor and all foreground cutouts.
## It preserves the original lighting and only animates emissive/glass materials.
const Set = preload("res://scripts/laboratory_set.gd")
const SURFACE = preload("res://scripts/laboratory_set.gdshader")
var scene: SubViewport
var material: ShaderMaterial
func _init() -> void:
 scene = SubViewport.new()
 scene.size = Vector2i(960,640)
 scene.disable_3d = true
 scene.transparent_bg = true
 scene.render_target_update_mode = SubViewport.UPDATE_DISABLED
 add_child(scene)
 var sprite := Sprite2D.new()
 sprite.centered = false
 sprite.texture = Set.TEXTURE
 sprite.position = Set.ORIGIN
 sprite.scale = Vector2.ONE*Set.SCALE
 material = ShaderMaterial.new()
 material.shader = SURFACE
 sprite.material = material
 scene.add_child(sprite)
func configure(_bounds: Rect2, _casters: Array[Dictionary], _nucleus: Vector2) -> void: pass
func present(time: float, alarm: bool, active: bool = true) -> void:
 scene.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
 material.set_shader_parameter("lab_time",time)
 material.set_shader_parameter("alarm",1.0 if alarm else 0.0)
