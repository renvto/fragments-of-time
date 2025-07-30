extends ChapterScene

var levelLayerActive = 1 
var onEnding = false
var speedrun_time = 0.0
var minutes := 0
var seconds := 0
var milliseconds := 0

func _ready():
	chapter_number = 3
	chapter_title = "Capitulo III"
	%Lado1.enabled = true
	%Lado2.enabled = false
	await super._ready()
	$VoidLimit.body_entered.connect(_on_void_limit_body_entered)
	$End.body_entered.connect(_on_end_body_entered)
	for espinho in $Espinhos.get_children():
		if espinho is Area2D:
			espinho.body_entered.connect(_on_espinho_body_entered)
	if GlobalVariables.speedrun:
		$SpeedrunCanvas.visible = true
	pass
	
func _process(delta: float) -> void:
	if GlobalVariables.speedrun and not onEnding:
		speedrun_time += delta
		minutes = int(speedrun_time) / 60
		seconds = int(speedrun_time) % 60
		milliseconds = int((speedrun_time - int(speedrun_time)) * 100)
		$SpeedrunCanvas/MarginContainer/Label.text = "%02d:%02d.%02d" % [minutes, seconds, milliseconds]
	
func _on_checkpoint_activated(checkpoint_id):
	super._on_checkpoint_activated(checkpoint_id)
	
	match checkpoint_id:
		"checkpoint_1":
			print("Primeiro checkpoint do capítulo 2 ativado!")
		"checkpoint_2":
			print("Segundo checkpoint do capítulo 2 ativado!")


func _on_void_limit_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		reset_level()
	
func _input(event: InputEvent) -> void:
	if onEnding:
		if event.is_action_pressed("jump"):
			get_tree().change_scene_to_file("res://UI/menu/main/menu.tscn")
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			return
	if event.is_action_pressed("time_change") or (event is InputEventKey and event.keycode == KEY_R and event.pressed):
		_on_time_change()
	

func _on_time_change():
	if levelLayerActive == 1:
		%Lado1.enabled = false
		%Lado2.enabled = true
		levelLayerActive = 2
	elif levelLayerActive == 2:
		%Lado2.enabled = false
		%Lado1.enabled = true
		levelLayerActive = 1
		
func reset_level():
	$CanvasLayer/ColorRect.visible = true
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	await super._ready()
	%Lado1.enabled = true
	%Lado2.enabled = false
	levelLayerActive = 1
	$AnimationPlayer.play("fade_out")
	await $AnimationPlayer.animation_finished
	$CanvasLayer/ColorRect.visible = false


func _on_end_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		$end.visible = true
		$AnimationPlayer.play("fade_in_end")
		onEnding = true
		GlobalVariables.controlsDisabled = true
		$SpeedrunCanvas.visible = false
		if GlobalVariables.speedrun:
			$end/Control/speedrun/speedrun_label.text = "Tempo: " + "%02d:%02d.%02d" % [minutes, seconds, milliseconds]
			$end/Control/speedrun.visible = true
			$SpeedrunCanvas.visible = false
			
func _on_espinho_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		GlobalVariables.controlsDisabled = true
		body.die()
		reset_level()

func _unhandled_input(event):
	if event.is_action_pressed("esc"):
		get_tree().change_scene_to_file("res://UI/menu/main/menu.tscn")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
