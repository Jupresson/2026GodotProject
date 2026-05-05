@tool
extends Node3D

@onready var rotation_preview: Node3D = $RotationPreview
@onready var rotation_preview_shaft: MeshInstance3D = $RotationPreview/Shaft
@onready var rotation_preview_head: MeshInstance3D = $RotationPreview/Head

@export var spawn_facing_y_degrees: float = 0.0:
	get:
		return _spawn_facing_y_degrees
	set(value):
		_spawn_facing_y_degrees = value
		_update_rotation_preview()

var _spawn_facing_y_degrees: float = 0.0


func _ready() -> void:
	if not Engine.is_editor_hint():
		if is_instance_valid(rotation_preview_shaft):
			rotation_preview_shaft.visible = false
		if is_instance_valid(rotation_preview_head):
			rotation_preview_head.visible = false
		return
	_update_rotation_preview()


func _update_rotation_preview() -> void:
	if not Engine.is_editor_hint():
		return
	if not is_instance_valid(rotation_preview):
		return
	rotation_preview.rotation_degrees = Vector3(0.0, _spawn_facing_y_degrees, 0.0)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("respawnpoint set "+ str(self.global_position))
		var spawn_facing_radians := Vector3(0.0, deg_to_rad(_spawn_facing_y_degrees), 0.0)
		GameManager.set_checkpoint(self.global_position, spawn_facing_radians)
		_remove()

func _remove():
	self.queue_free()