extends Control
class_name PerformanceDebugUI


@export var update_interval_seconds: float = 0.25
@export var show_default_fps: bool = true

@onready var _metrics_container: VBoxContainer = %MetricsContainer
@onready var _fps_value_label: Label = %FPSValue
@onready var _cpu_usage_value_label: Label = %CPUUsageValue
@onready var _gpu_usage_value_label: Label = %GPUUsageValue
@onready var _frame_time_value_label: Label = %FrameTimeValue
@onready var _physics_time_value_label: Label = %PhysicsTimeValue
@onready var _object_count_value_label: Label = %ObjectCountValue
@onready var _ram_usage_value_label: Label = %RamUsageValue

var _metric_value_labels: Dictionary = {}
var _metric_providers: Dictionary = {}
var _refresh_time: float = 0.0


func _ready() -> void:
	var viewport := get_viewport()
	if viewport != null:
		RenderingServer.viewport_set_measure_render_time(viewport.get_viewport_rid(), true)

	_bind_scene_metric_label("FPS", _fps_value_label)
	_bind_scene_metric_label("CPU Usage", _cpu_usage_value_label)
	_bind_scene_metric_label("GPU Usage", _gpu_usage_value_label)
	_bind_scene_metric_label("Frame Time", _frame_time_value_label)
	_bind_scene_metric_label("Physics Time", _physics_time_value_label)
	_bind_scene_metric_label("Object Count", _object_count_value_label)
	_bind_scene_metric_label("RAM Usage", _ram_usage_value_label)

	if show_default_fps:
		register_metric("FPS", func() -> Variant:
			return Engine.get_frames_per_second()
		)

	register_performance_monitor("Frame Time", Performance.TIME_PROCESS, func(raw_value: Variant) -> String:
		return "%0.2f ms" % (float(raw_value) * 1000.0)
	)
	register_performance_monitor("Physics Time", Performance.TIME_PHYSICS_PROCESS, func(raw_value: Variant) -> String:
		return "%0.2f ms" % (float(raw_value) * 1000.0)
	)
	register_metric("CPU Usage", func() -> String:
		return _format_usage_percent(_get_cpu_usage_percent())
	)
	register_metric("GPU Usage", func() -> String:
		return _format_usage_percent(_get_gpu_usage_percent())
	)
	register_performance_monitor("Object Count", Performance.OBJECT_COUNT)
	register_performance_monitor("RAM Usage", Performance.MEMORY_STATIC, _format_bytes)
	_refresh_metrics()


func _process(delta: float) -> void:
	_refresh_time += delta
	if _refresh_time < update_interval_seconds:
		return

	_refresh_time = 0.0
	_refresh_metrics()


func register_metric(metric_name: String, value_provider: Callable) -> void:
	if metric_name.is_empty() or not value_provider.is_valid():
		return

	_metric_providers[metric_name] = value_provider

	if not _metric_value_labels.has(metric_name):
		var metric_value_label := _create_metric_row(metric_name)
		if metric_value_label == null:
			return
		_metric_value_labels[metric_name] = metric_value_label

	_refresh_metric(metric_name)


func register_performance_monitor(metric_name: String, monitor_id: int, formatter: Callable = Callable()) -> void:
	var provider := func() -> Variant:
		var raw_value: Variant = Performance.get_monitor(monitor_id)
		if formatter.is_valid():
			return formatter.call(raw_value)
		return raw_value

	register_metric(metric_name, provider)


func remove_metric(metric_name: String) -> void:
	if not _metric_value_labels.has(metric_name):
		return

	var metric_label: Label = _metric_value_labels[metric_name]
	var metric_row: Control = metric_label.get_parent()
	metric_row.queue_free()
	_metric_value_labels.erase(metric_name)
	_metric_providers.erase(metric_name)


func clear_metrics() -> void:
	for metric_name in _metric_value_labels.keys():
		var metric_label: Label = _metric_value_labels[metric_name]
		var metric_row: Control = metric_label.get_parent()
		metric_row.queue_free()

	_metric_value_labels.clear()
	_metric_providers.clear()


func _bind_scene_metric_label(metric_name: String, metric_label: Label) -> void:
	if metric_label == null:
		return

	_metric_value_labels[metric_name] = metric_label


func _create_metric_row(metric_name: String) -> Label:
	if _metrics_container == null:
		return null

	var metric_row := HBoxContainer.new()
	metric_row.name = "%sRow" % metric_name.replace(" ", "")
	_metrics_container.add_child(metric_row)

	var metric_name_label := Label.new()
	metric_name_label.name = "%sLabel" % metric_name.replace(" ", "")
	metric_name_label.text = metric_name
	metric_row.add_child(metric_name_label)

	var metric_value_label := Label.new()
	metric_value_label.name = "%sValue" % metric_name.replace(" ", "")
	metric_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metric_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	metric_value_label.text = "..."
	metric_row.add_child(metric_value_label)

	return metric_value_label


func _refresh_metric(metric_name: String) -> void:
	if not _metric_providers.has(metric_name) or not _metric_value_labels.has(metric_name):
		return

	var provider: Callable = _metric_providers[metric_name]
	if not provider.is_valid():
		return

	var metric_value: Variant = provider.call()
	var metric_label: Label = _metric_value_labels[metric_name]
	metric_label.text = str(metric_value)


func _refresh_metrics() -> void:
	for metric_name in _metric_providers.keys():
		_refresh_metric(metric_name)


func _format_bytes(raw_value: Variant) -> String:
	var bytes: float = float(raw_value)
	var megabytes: float = bytes / (1024.0 * 1024.0)
	return "%0.1f MB" % megabytes


func _get_cpu_usage_percent() -> float:
	var viewport := get_viewport()
	if viewport == null:
		return 0.0

	var frame_budget_ms := _get_frame_budget_ms()
	var viewport_rid := viewport.get_viewport_rid()
	var setup_time_ms := RenderingServer.get_frame_setup_time_cpu()
	var render_time_ms := RenderingServer.viewport_get_measured_render_time_cpu(viewport_rid)
	return clamp(((setup_time_ms + render_time_ms) / frame_budget_ms) * 100.0, 0.0, 100.0)


func _get_gpu_usage_percent() -> float:
	var viewport := get_viewport()
	if viewport == null:
		return 0.0

	var frame_budget_ms := _get_frame_budget_ms()
	var render_time_ms := RenderingServer.viewport_get_measured_render_time_gpu(viewport.get_viewport_rid())
	return clamp((render_time_ms / frame_budget_ms) * 100.0, 0.0, 100.0)


func _get_frame_budget_ms() -> float:
	var frame_time_ms := float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0
	if frame_time_ms <= 0.0:
		return 1000.0 / 60.0

	return frame_time_ms


func _format_usage_percent(percent: float) -> String:
	return "%0.1f%%" % percent
