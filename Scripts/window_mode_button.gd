extends Control

@onready var option_button: OptionButton = $HBoxContainer/OptionButton

const WINDOW_MODE_ARRAY : Array[String] = [
	"Fullscreen",
	"Window Mode",
	"Borderless Window",
	"Borderless Fullscreen"
]
func load_data() -> void:
	on_window_mode_selected(SettingsDataContainer.get_window_mode_index())
func _ready():
	add_window_mode_items()
	load_data()
	option_button.item_selected.connect(on_window_mode_selected)
	
func add_window_mode_items() -> void:
	for window_mode in WINDOW_MODE_ARRAY:
		option_button.add_item(window_mode)

func on_window_mode_selected(index : int ) -> void:
	SettingsSignalBus.emit_on_window_mode_selected(index)
	option_button.select(SettingsDataContainer.get_window_mode_index())
	match index:
		0: #fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		1: #window mode
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		2: #bordelesse window
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		3: #bordeless fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
