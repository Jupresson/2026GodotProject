extends VBoxContainer

signal render_scaling_changed(mode: int, scale: float)
signal camera_upscale_changed(upscale: float)

@onready var resolution_option_button: OptionButton = $Tabs/DisplayTab/ResolutionOptionButton
@onready var full_screen_check_box: CheckBox = $Tabs/DisplayTab/FullScreenCheckBox
@onready var vsync_check_box: CheckBox = $Tabs/DisplayTab/VsyncCheckBox
@onready var screen_selector: OptionButton = $Tabs/DisplayTab/ScreenSelector

@onready var scaler_option_button: OptionButton = $Tabs/GraphicsTab/Scaler
@onready var scale_label: Label = $Tabs/GraphicsTab/ScaleBox/ScaleLabel
@onready var scale_slider: HSlider = $Tabs/GraphicsTab/ScaleBox/ScaleSlider
@onready var fsr_options: OptionButton = $Tabs/GraphicsTab/FSROptions
@onready var camera_upscale_label: Label = $Tabs/GraphicsTab/CameraUpscaleBox/CameraUpscaleLabel
@onready var camera_upscale_slider: HSlider = $Tabs/GraphicsTab/CameraUpscaleBox/CameraUpscaleSlider

@export var projection_node_path: NodePath

var _projection_controller: Node = null
var _active_scaling_mode: int = Viewport.SCALING_3D_MODE_BILINEAR
var _last_windowed_size: Vector2i = Vector2i.ZERO
var _last_windowed_position: Vector2i = Vector2i.ZERO

var _resolutions: Dictionary = {
	"7680x4320": Vector2i(7680,4320), # 8K UHD
	"5120x2880": Vector2i(5120,2880), # 5K
	"3840x2160": Vector2i(3840,2160), # 4K UHD
	"3440x1440": Vector2i(3440,1440), # Ultrawide QHD
	"2560x1440": Vector2i(2560,1440), # 1440p
	"2560x1080": Vector2i(2560,1080), # Ultrawide FHD
	"1920x1080": Vector2i(1920,1080), # 1080p
	"1600x900": Vector2i(1600,900),
	"1366x768": Vector2i(1366,768),
	"1280x720": Vector2i(1280,720) # 720p
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	render_scaling_changed.connect(_apply_render_scaling)
	camera_upscale_changed.connect(_apply_camera_upscale)
	_resolve_projection_controller()
	_connect_window_signals()
	check_variables()
	_add_resolutions()
	_get_screens()
	_on_scaler_item_selected(scaler_option_button.selected)
	_on_camera_upscale_slider_value_changed(camera_upscale_slider.value)
	_sync_window_ui()

func check_variables():
	var _window = get_window()
	var _mode = _window.get_mode()
	if _mode == Window.MODE_WINDOWED:
		_last_windowed_size = _window.get_size()
		_last_windowed_position = _window.get_position()
	
	if _mode == Window.MODE_FULLSCREEN:
		resolution_option_button.set_disabled(true)
		full_screen_check_box.set_pressed_no_signal(true)
		
	if DisplayServer.window_get_vsync_mode(_window.get_window_id()) == DisplayServer.VSYNC_ENABLED:
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
	var _window := get_window()
	_window.set_size(_resolutions[_id])
	_last_windowed_size = _window.get_size()
	_center_window()

func _center_window():
	if get_window().get_mode() != Window.MODE_WINDOWED:
		return

	@warning_ignore("integer_division")
	var _center_screen = DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
	var _window_size = get_window().get_size_with_decorations()
	@warning_ignore("integer_division")
	get_window().set_position(_center_screen - _window_size / 2)
	_last_windowed_position = get_window().get_position()


func _on_full_screen_check_box_toggled(_toggled_on: bool) -> void:
	_set_fullscreen_enabled(_toggled_on)


func _on_scale_slider_value_changed(_value: float) -> void:
	var _resolution_scale = _value / 100.00
	var resolution_text = str(round(get_window().get_size().x * _resolution_scale)) + "x" + str(round(get_window().get_size().y * _resolution_scale))
	scale_label.set_text(str(_value) + "% - " + resolution_text)
	render_scaling_changed.emit(_active_scaling_mode, _resolution_scale)


func _on_camera_upscale_slider_value_changed(_value: float) -> void:
	var _camera_upscale := _value / 100.0
	var _window_size := get_window().get_size()
	var _rendered_size := Vector2(round(_window_size.x * _camera_upscale), round(_window_size.y * _camera_upscale))
	camera_upscale_label.set_text(str(round(_value)) + "% - " + str(int(_rendered_size.x)) + "x" + str(int(_rendered_size.y)))
	camera_upscale_changed.emit(_camera_upscale)
	

func _on_scaler_item_selected(_index: int) -> void:
	match _index:
		1:
			_active_scaling_mode = Viewport.SCALING_3D_MODE_BILINEAR
			scale_slider.show()
			scale_label.show()
			fsr_options.hide()
			# Bilinear should run at native scale to avoid fullscreen artifacts after FSR.
			if scale_slider.value < 100.0:
				scale_slider.set_value_no_signal(100.0)
			_on_scale_slider_value_changed(scale_slider.value)
		2:
			_active_scaling_mode = Viewport.SCALING_3D_MODE_FSR2
			scale_label.hide()
			scale_slider.hide()
			fsr_options.show()
			if fsr_options.selected <= 0:
				fsr_options.select(4) # Ultra Quality
			_on_fsr_options_item_selected(fsr_options.selected)


func _on_fsr_options_item_selected(_index: int) -> void:
	match _index:
		1:
			scale_slider.set_value_no_signal(50.00)
			_on_scale_slider_value_changed(50.00)
		2:
			scale_slider.set_value_no_signal(59.00)
			_on_scale_slider_value_changed(59.00)
		3:
			scale_slider.set_value_no_signal(67.00)
			_on_scale_slider_value_changed(67.00)
		4:
			scale_slider.set_value_no_signal(77.00)
			_on_scale_slider_value_changed(77.00)
		_:
			scale_slider.set_value_no_signal(77.00)
			_on_scale_slider_value_changed(77.00)


func _on_vsync_check_box_toggled(_toggled_on: bool) -> void:
	var _window := get_window()
	var _vsync_mode := DisplayServer.VSYNC_ENABLED if _toggled_on else DisplayServer.VSYNC_DISABLED
	call_deferred("_apply_vsync_mode", _vsync_mode, _window.get_window_id())


func _apply_vsync_mode(vsync_mode: int, window_id: int) -> void:
	DisplayServer.window_set_vsync_mode(vsync_mode, window_id)


func _apply_camera_upscale(upscale: float) -> void:
	if _projection_controller and _projection_controller.has_method("set_pipeline_upscale"):
		_projection_controller.call("set_pipeline_upscale", upscale)
		return

	if _projection_controller and "upscale" in _projection_controller:
		_projection_controller.upscale = upscale

func _get_screens():
	var _screens = DisplayServer.get_screen_count()
	
	for _s in _screens:
		screen_selector.add_item("Screen: " + str(_s))


func _on_screen_selector_item_selected(_index: int) -> void:
	var _window = get_window()
	
	var _was_fullscreen := _window.get_mode() == Window.MODE_FULLSCREEN
	if _was_fullscreen:
		_set_fullscreen_enabled(false)

	_window.set_current_screen(_index)

	if _was_fullscreen:
		_set_fullscreen_enabled(true)


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


func _set_fullscreen_enabled(enabled: bool) -> void:
	var _window := get_window()
	if enabled:
		if _window.get_mode() == Window.MODE_WINDOWED:
			_last_windowed_size = _window.get_size()
			_last_windowed_position = _window.get_position()
		_window.set_mode(Window.MODE_FULLSCREEN)
	else:
		_window.set_mode(Window.MODE_WINDOWED)
		if _last_windowed_size != Vector2i.ZERO:
			_window.set_size(_last_windowed_size)
		if _last_windowed_position != Vector2i.ZERO:
			_window.set_position(_last_windowed_position)
		else:
			_center_window()

	_sync_window_ui()


func _connect_window_signals() -> void:
	var _window := get_window()
	if _window and not _window.size_changed.is_connected(_on_window_size_changed):
		_window.size_changed.connect(_on_window_size_changed)


func _on_window_size_changed() -> void:
	if get_window().get_mode() == Window.MODE_WINDOWED:
		_last_windowed_size = get_window().get_size()
		_last_windowed_position = get_window().get_position()

	_sync_window_ui()


func _sync_window_ui() -> void:
	var _is_fullscreen := get_window().get_mode() == Window.MODE_FULLSCREEN
	resolution_option_button.set_disabled(_is_fullscreen)
	full_screen_check_box.set_pressed_no_signal(_is_fullscreen)
	set_resolution_text()


func _on_native_sharp_button_pressed() -> void:
	_on_scaler_item_selected(1)
	if scale_slider.value < 100.0:
		scale_slider.set_value_no_signal(100.0)
	_on_scale_slider_value_changed(scale_slider.value)
	camera_upscale_slider.set_value_no_signal(200.0)
	_on_camera_upscale_slider_value_changed(200.0)


func _on_performance_button_pressed() -> void:
	_on_scaler_item_selected(2)
	fsr_options.select(1)
	_on_fsr_options_item_selected(1)
	camera_upscale_slider.set_value_no_signal(150.0)
	_on_camera_upscale_slider_value_changed(150.0)


func _on_balanced_button_pressed() -> void:
	_on_scaler_item_selected(2)
	fsr_options.select(2)
	_on_fsr_options_item_selected(2)
	camera_upscale_slider.set_value_no_signal(175.0)
	_on_camera_upscale_slider_value_changed(175.0)


func _on_quality_button_pressed() -> void:
	_on_scaler_item_selected(2)
	fsr_options.select(3)
	_on_fsr_options_item_selected(3)
	camera_upscale_slider.set_value_no_signal(200.0)
	_on_camera_upscale_slider_value_changed(200.0)


func _on_ultra_button_pressed() -> void:
	_on_scaler_item_selected(2)
	fsr_options.select(4)
	_on_fsr_options_item_selected(4)
	camera_upscale_slider.set_value_no_signal(225.0)
	_on_camera_upscale_slider_value_changed(225.0)

	
