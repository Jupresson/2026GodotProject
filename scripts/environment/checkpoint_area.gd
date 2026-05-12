@tool
class_name Checkpoint extends Area3D

@export var spawn_rotation: Vector3 = Vector3.ZERO

func _func_godot_apply_properties(entity_properties: Dictionary) -> void:
	#spawn_position = entity_properties.get("spawn_position", spawn_position) as Vector3
	spawn_rotation = entity_properties.get("spawn_rotation", spawn_rotation) as Vector3

func _ready() -> void:
	if not Engine.is_editor_hint():
		_start()

func _start() -> void: # used just for a cleaner arcitehture for all entitys that has scripts.
	body_entered.connect(_on_area_3d_body_entered)

#func _exit_tree() -> void: # Used for stopping timers, killing tweens, freeing helper nodes, disconnecting signals from other nodes...

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		GameManager.set_checkpoint(body.global_position, spawn_rotation)
		self.queue_free()
