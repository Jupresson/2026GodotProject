extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	InputManager.set_input_enabled(true)
	GameManager.respawn_player()