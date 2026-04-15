extends Control

@onready var _status_label: Label = $Center/VBox/StatusLabel
@onready var _progress_bar: ProgressBar = $Center/VBox/ProgressBar


func _ready() -> void:
	set_progress(0.0)
	set_status_text("Loading...")


func set_progress(value: float) -> void:
	_progress_bar.value = clampf(value, 0.0, 100.0)


func set_status_text(text: String) -> void:
	_status_label.text = text
