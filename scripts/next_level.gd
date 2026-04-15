extends Node3D

@export_file("*.tscn") var next_scene_path: String = ""

var _has_triggered := false

func _on_area_3d_body_entered(body: Node3D) -> void:
	if _has_triggered or not body.is_in_group("player"):
		return

	if next_scene_path.is_empty():
		push_error("Next scene path is empty on %s" % name)
		return

	_has_triggered = true
	SceneManager.change_scene_with_loading(next_scene_path, 2.0)