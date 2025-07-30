extends Control

@onready var check_box: CheckBox = $HBoxContainer/CheckBox

func _ready() -> void:
	load_data()

func load_data() -> void:
	var is_vsync_enabled = SettingsDataContainer.get_vsync()
	check_box.button_pressed = is_vsync_enabled
	_on_check_box_toggled(is_vsync_enabled)

func _on_check_box_toggled(toggled_on: bool) -> void:
	SettingsSignalBus.emit_on_vsync_set(toggled_on)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if toggled_on else DisplayServer.VSYNC_DISABLED)
