extends Node
class_name SceneManagerClass

const LOADING_SCENE_PATH := "res://ui/scenes/loading_screen_ui.tscn"
const DEFAULT_MIN_LOADING_TIME := 1.0
const FAKE_PROGRESS_CAP := 99.0
const PROGRESS_SPEED := 120.0

signal scene_change_started(scene_path: String)
signal scene_change_finished(scene_path: String)
signal scene_change_failed(scene_path: String, error_code: int)

var _is_switching := false


func change_scene(scene_path: String) -> void:
	if _is_switching:
		return

	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("Scene not found: %s" % scene_path)
		scene_change_failed.emit(scene_path, ERR_DOES_NOT_EXIST)
		return

	_is_switching = true
	scene_change_started.emit(scene_path)
	call_deferred("_perform_scene_change", scene_path)


func change_scene_with_loading(scene_path: String, min_loading_time: float = DEFAULT_MIN_LOADING_TIME) -> void:
	if _is_switching:
		return

	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("Scene not found: %s" % scene_path)
		scene_change_failed.emit(scene_path, ERR_DOES_NOT_EXIST)
		return

	_is_switching = true
	scene_change_started.emit(scene_path)
	call_deferred("_perform_scene_change_with_loading", scene_path, maxf(min_loading_time, 0.0))


func reload_current_scene() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		push_error("No current scene to reload")
		return

	var current_path := current_scene.scene_file_path
	if current_path.is_empty():
		push_error("Current scene has no file path and cannot be reloaded")
		return

	change_scene(current_path)


func _perform_scene_change(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Failed to change scene to %s (error %s)" % [scene_path, error])
		scene_change_failed.emit(scene_path, error)
		_is_switching = false
		return

	scene_change_finished.emit(scene_path)
	_is_switching = false


func _perform_scene_change_with_loading(scene_path: String, min_loading_time: float) -> void:
	var loading_screen := _show_loading_screen()
	if loading_screen != null and loading_screen.has_method("set_status_text"):
		loading_screen.call("set_status_text", "Loading level...")

	var request_error := ResourceLoader.load_threaded_request(scene_path, "PackedScene")
	if request_error != OK:
		push_error("Failed to request threaded load for %s (error %s)" % [scene_path, request_error])
		scene_change_failed.emit(scene_path, request_error)
		_hide_loading_screen(loading_screen)
		_is_switching = false
		return

	var elapsed := 0.0
	var progress := []
	var displayed_progress := 0.0

	while true:
		var delta := get_process_delta_time()
		elapsed += delta

		var status := ResourceLoader.load_threaded_get_status(scene_path, progress)
		var loaded_percent := 0.0
		if progress.size() > 0:
			loaded_percent = clampf(progress[0] * 100.0, 0.0, 100.0)

		var min_time_percent := FAKE_PROGRESS_CAP
		if min_loading_time > 0.0:
			min_time_percent = clampf((elapsed / min_loading_time) * FAKE_PROGRESS_CAP, 0.0, FAKE_PROGRESS_CAP)

		var loading_done := status == ResourceLoader.THREAD_LOAD_LOADED
		var min_time_done := elapsed >= min_loading_time

		var target_progress := maxf(minf(loaded_percent, FAKE_PROGRESS_CAP), min_time_percent)
		if loading_done and min_time_done:
			target_progress = 100.0

		displayed_progress = move_toward(displayed_progress, target_progress, PROGRESS_SPEED * delta)

		if loading_screen != null and loading_screen.has_method("set_progress"):
			loading_screen.call("set_progress", displayed_progress)

		if loading_done and min_time_done and loading_screen != null and loading_screen.has_method("set_status_text"):
			loading_screen.call("set_status_text", "Finalizing...")

		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Failed to load scene resource: %s" % scene_path)
			scene_change_failed.emit(scene_path, ERR_CANT_OPEN)
			_hide_loading_screen(loading_screen)
			_is_switching = false
			return

		if loading_done and min_time_done and displayed_progress >= 99.9:
			break

		await get_tree().process_frame

	var packed_scene := ResourceLoader.load_threaded_get(scene_path)
	if packed_scene == null or not (packed_scene is PackedScene):
		push_error("Loaded resource is not a PackedScene: %s" % scene_path)
		scene_change_failed.emit(scene_path, ERR_PARSE_ERROR)
		_hide_loading_screen(loading_screen)
		_is_switching = false
		return

	var error := get_tree().change_scene_to_packed(packed_scene)
	if error != OK:
		push_error("Failed to change scene to %s (error %s)" % [scene_path, error])
		scene_change_failed.emit(scene_path, error)
		_hide_loading_screen(loading_screen)
		_is_switching = false
		return

	_hide_loading_screen(loading_screen)
	scene_change_finished.emit(scene_path)
	_is_switching = false


func _show_loading_screen() -> Node:
	if not ResourceLoader.exists(LOADING_SCENE_PATH):
		push_error("Loading scene not found: %s" % LOADING_SCENE_PATH)
		return null

	var loading_resource: PackedScene = load(LOADING_SCENE_PATH) as PackedScene
	if loading_resource == null:
		push_error("Loading scene could not be loaded: %s" % LOADING_SCENE_PATH)
		return null

	var loading_screen: Node = loading_resource.instantiate()
	get_tree().root.add_child(loading_screen)
	return loading_screen


func _hide_loading_screen(loading_screen: Node) -> void:
	if loading_screen != null and is_instance_valid(loading_screen):
		loading_screen.queue_free()