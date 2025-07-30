class_name HotkeyRebindButton

extends Control

@onready var label = $HBoxContainer/Label as Label
@onready var button = $HBoxContainer/Button as Button
@export var action_name : String = "move_left"

func _ready():
	set_process_unhandled_key_input(false)
	set_action_name()
	set_text_for_key()
	load_keybinds()
	
func load_keybinds() -> void:
	rebind_action_key(SettingsDataContainer.get_keybind(action_name))

func set_action_name() -> void:
	label.text = "unassigned"

	match action_name:
		"move_left":
			label.text = "Mover para a Esquerda"
		"move_right":
			label.text = "Mover para a Direita"
		"move_down":
			label.text = "Mover para Baixo"
		"jump":
			label.text = "Pular"
		"time_change":
			label.text = "Mudar o Tempo"
		"dash":
			label.text = "Impulso"

func set_text_for_key() -> void:
	var action_events = InputMap.action_get_events(action_name)
	if action_events.size() > 0:
		var action_event = action_events[0]
		var action_keycode = OS.get_keycode_string(action_event.physical_keycode)
		button.text = "%s" % action_keycode

func _on_button_toggled(toggled_on):
	var rebind_buttons: Array[HotkeyRebindButton] = []
	for node in get_tree().get_nodes_in_group("hotkey_button"):
		if node is HotkeyRebindButton:
			rebind_buttons.append(node)

	if toggled_on:
		button.text = "..."
		set_process_unhandled_key_input(toggled_on)
		for rebind_button in rebind_buttons:
			if rebind_button.action_name != self.action_name:
				rebind_button.button.toggle_mode = false
				rebind_button.set_process_unhandled_key_input(false)
	else:
		for rebind_button in rebind_buttons:
			if rebind_button.action_name != self.action_name:
				rebind_button.button.toggle_mode = true
				rebind_button.set_process_unhandled_key_input(false)
		set_text_for_key()

func _unhandled_key_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		rebind_action_key(event)
		button.set_pressed_no_signal(false) 
		
func rebind_action_key(event) -> void:
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, event)
	SettingsDataContainer.set_keybind(action_name, event)
	set_process_unhandled_key_input(false)
	set_text_for_key()
	set_action_name()
	reset_buttons()

func reset_buttons():
	var rebind_buttons: Array[HotkeyRebindButton] = []
	for node in get_tree().get_nodes_in_group("hotkey_button"):
		if node is HotkeyRebindButton:
			rebind_buttons.append(node)
	print("teste")
	for button in rebind_buttons:
		button.button.toggle_mode = true
		button.set_process_unhandled_key_input(false)
