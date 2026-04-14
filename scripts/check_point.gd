extends Node3D

@export var spawn_rotation: Vector3 = Vector3.ZERO

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("respawnpoint set "+ str(self.global_position))
		GameManager.set_checkpoint(self.global_position, spawn_rotation)