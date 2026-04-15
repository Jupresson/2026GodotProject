extends Control

const OPTIONS_SCENE_PATH := "res://ui/scenes/options_ui.tscn"
const START_SCENE_PATH := "res://scenes/levels/level_0.tscn"

func _on_start_pressed() -> void:
	SceneManager.change_scene_with_loading(START_SCENE_PATH, 2.0)


func _on_settings_pressed() -> void:
	SceneManager.change_scene(OPTIONS_SCENE_PATH)


func _on_quit_pressed() -> void:
	get_tree().quit()
