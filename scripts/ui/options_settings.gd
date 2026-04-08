extends VBoxContainer

signal render_scaling_changed(mode: int, scale: float)

@onready var resolution_option_button: OptionButton = $ResolutionOptionButton
@onready var full_screen_check_box: CheckBox = $FullScreenCheckBox
@onready var scale_label: Label = $ScaleBox/ScaleLabel
@onready var scale_slider: HSlider = $ScaleBox/ScaleSlider
@onready var fsr_options: OptionButton = $FSROptions
@onready var vsync_check_box: CheckBox = $VsyncCheckBox
@onready var screen_selector: OptionButton = $ScreenSelector

@export var projection_node_path: NodePath

var _projection_controller: Node = null
var _active_scaling_mode: int = Viewport.SCALING_3D_MODE_BILINEAR

var _resolutions: Dictionary = {"3840x2160":Vector2i(3840,2160),
								"2560x1440":Vector2i(2560,1080),
								"1920x1080":Vector2i(1920,1080),
								"1366x768":Vector2i(1366,768),
								"1536x864":Vector2i(1536,864),
								"1280x720":Vector2i(1280,720),
								"1440x900":Vector2i(1440,900),
								"1600x900":Vector2i(1600,900),
								"1024x600":Vector2i(1024,600),
								"800x600": Vector2i(800,600)}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	render_scaling_changed.connect(_apply_render_scaling)
	_resolve_projection_controller()
	check_variables()
	_add_resolutions()
	_get_screens()
	_on_scaler_item_selected(1)

func check_variables():
	var _window = get_window()
	var _mode = _window.get_mode()
	
	if _mode == Window.MODE_FULLSCREEN:
		resolution_option_button.set_disabled(true)
		full_screen_check_box.set_pressed_no_signal(true)
		
	if DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED:
		vsync_check_box.set_pressed_no_signal(true)


func set_resolution_text():
	var resolution_text = str(get_window().get_size().x) + "x" + str(get_window().get_size().y)
	resolution_option_button.set_text(resolution_text)
	
	
func _add_resolutions():
	var _current_resolution = get_window().get_window().get_size()
	var _id = 0
	
	for _r in _resolutions:
		resolution_option_button.add_item(_r, _id)
		if _resolutions[_r] == _current_resolution:
			resolution_option_button.select(_id)
		
		_id += 1


func _on_option_button_item_selected(_index: int) -> void:
	var _id = resolution_option_button.get_item_text(_index)
	get_window().set_size(_resolutions[_id])
	_center_window()

func _center_window():
	@warning_ignore("integer_division")
	var _center_screen = DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
	var _window_size = get_window().get_size_with_decorations()
	@warning_ignore("integer_division")
	get_window().set_position(_center_screen - _window_size / 2)


func _on_full_screen_check_box_toggled(_toggled_on: bool) -> void:
	resolution_option_button.set_disabled(_toggled_on)
	if _toggled_on:
		get_window().set_mode(Window.MODE_FULLSCREEN)
	else:
		get_window().set_mode(Window.MODE_WINDOWED)
		_center_window()
	
	get_tree().create_timer(0.05).timeout.connect(set_resolution_text) # helps with some bugs (give time to window to resize)
	@warning_ignore("unused_parameter")


func _on_scale_slider_value_changed(_value: float) -> void:
	var _resolution_scale = _value / 100.00
	var resolution_text = str(round(get_window().get_size().x * _resolution_scale)) + "x" + str(round(get_window().get_size().y * _resolution_scale))
	scale_label.set_text(str(_value) + "% - " + resolution_text)
	render_scaling_changed.emit(_active_scaling_mode, _resolution_scale)
	

func _on_scaler_item_selected(_index: int) -> void:
	var _viewport = get_viewport()
	match _index:
		1:
			_active_scaling_mode = Viewport.SCALING_3D_MODE_BILINEAR
			scale_slider.show()
			scale_label.show()
			_viewport.set_scaling_3d_mode(Viewport.SCALING_3D_MODE_BILINEAR)
			fsr_options.hide()
			render_scaling_changed.emit(_active_scaling_mode, scale_slider.value / 100.0)
		2:
			_active_scaling_mode = Viewport.SCALING_3D_MODE_FSR2
			scale_label.hide()
			scale_slider.hide()
			_viewport.set_scaling_3d_mode(Viewport.SCALING_3D_MODE_FSR2)
			fsr_options.show()
			render_scaling_changed.emit(_active_scaling_mode, scale_slider.value / 100.0)


func _on_fsr_options_item_selected(_index: int) -> void:
	match _index:
		1:
			_on_scale_slider_value_changed(50.00)
		2:
			_on_scale_slider_value_changed(59.00)
		3:
			_on_scale_slider_value_changed(67.00)
		4:
			_on_scale_slider_value_changed(77.00)


func _on_vsync_check_box_toggled(_toggled_on: bool) -> void:
	if _toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _get_screens():
	var _screens = DisplayServer.get_screen_count()
	
	for _s in _screens:
		screen_selector.add_item("Screen: " + str(_s))


func _on_screen_selector_item_selected(_index: int) -> void:
	var _window = get_window()
	
	var _mode = _window.get_mode()
	
	_window.set_mode(Window.MODE_WINDOWED)
	_window.set_current_screen(_index)
	
	if _mode == Window.MODE_FULLSCREEN:
		_window.set_mode(Window.MODE_FULLSCREEN)


func _resolve_projection_controller() -> void:
	if not projection_node_path.is_empty():
		_projection_controller = get_node_or_null(projection_node_path)

	if _projection_controller == null and get_tree().current_scene:
		_projection_controller = get_tree().current_scene.find_child("Projection", true, false)


func _apply_render_scaling(mode: int, scale: float) -> void:
	if _projection_controller and _projection_controller.has_method("set_external_render_scaling"):
		_projection_controller.call("set_external_render_scaling", mode, scale)
		return

	# Fallback when projection addon is not present in the scene.
	get_viewport().set_scaling_3d_mode(mode)
	get_viewport().set_scaling_3d_scale(scale)

	
