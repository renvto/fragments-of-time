extends Control

@onready var option_button: OptionButton = $HBoxContainer/OptionButton

const COMMON_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(800, 600),
	Vector2i(1024, 768),
	Vector2i(1152, 648),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

var available_resolutions: Array[Vector2i] = []

func _ready():
	option_button.item_selected.connect(on_resolution_selected)
	detect_available_resolutions()
	add_resolution_items()
	load_data()

func detect_available_resolutions() -> void:
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	
	for resolution in COMMON_RESOLUTIONS:
		if resolution.x <= screen_size.x and resolution.y <= screen_size.y:
			available_resolutions.append(resolution)
	
	available_resolutions.sort_custom(func(a, b): return a.x < b.x or (a.x == b.x and a.y < b.y))

func add_resolution_items() -> void:
	for resolution in available_resolutions:
		var resolution_text = "%d x %d" % [resolution.x, resolution.y]
		option_button.add_item(resolution_text)

func load_data() -> void:
	var current_resolution = SettingsDataContainer.get_resolution_index()
	on_resolution_selected(current_resolution)
	option_button.select(current_resolution)

func on_resolution_selected(index: int) -> void:
	SettingsSignalBus.emit_on_resolution_selected(index)
	var selected_resolution = available_resolutions[index]
	DisplayServer.window_set_size(selected_resolution)
	centre_window()

func centre_window():
	var centre_screen = DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
	var window_size = get_window().get_size_with_decorations()
	get_window().set_position(centre_screen - window_size / 2)
