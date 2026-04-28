extends Node
class_name InputManagerClass

signal input_capture_changed(is_input_enabled: bool)
signal mouse_look_input(relative: Vector2)

var is_input_enabled: bool = true


func _ready() -> void:
	is_input_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	input_capture_changed.emit(is_input_enabled)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if event is InputEventKey and event.echo:
			return
		toggle_input_enabled()
		get_viewport().set_input_as_handled()
		return

	if not is_input_enabled:
		return

	if event is InputEventMouseMotion:
		mouse_look_input.emit(event.relative)


func get_move_vector(left_action: String, right_action: String, forward_action: String, backward_action: String) -> Vector2:
	if not is_input_enabled:
		return Vector2.ZERO

	return Input.get_vector(left_action, right_action, forward_action, backward_action)


func is_action_pressed(action_name: String) -> bool:
	return is_input_enabled and Input.is_action_pressed(action_name)


func is_action_just_pressed(action_name: String) -> bool:
	return is_input_enabled and Input.is_action_just_pressed(action_name)


func set_input_enabled(enabled: bool) -> void:
	if is_input_enabled == enabled:
		return

	is_input_enabled = enabled
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if enabled else Input.MOUSE_MODE_VISIBLE

	input_capture_changed.emit(is_input_enabled)


func toggle_input_enabled() -> void:
	set_input_enabled(not is_input_enabled)
