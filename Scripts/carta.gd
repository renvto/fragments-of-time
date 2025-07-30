extends Area2D

@export var title: String
@export_multiline var text: String
@export_enum("Verde", "Roxo") var tema : String = "Roxo"

var is_player_in_area = false
var carta_aberta = false
var animacao_em_curso = false
var animacao_pendente: String = ""

@onready var label = $NinePatchLabel
@onready var animation_player = $AnimationPlayer

func _ready():
	label.visible = false
	label.modulate.a = 0.0
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	animation_player.animation_finished.connect(_on_animation_finished)
	if tema == "Verde":
		$NinePatchLabel.texture = preload("res://Sprites/UI/DialogTextBox/Verde/dialog-text-16x16-verde.png")


func _on_body_entered(body):
	if body.name == "Player":
		is_player_in_area = true
		tentar_animar("fade_in")

func _on_body_exited(body):
	if body.name == "Player":
		is_player_in_area = false
		tentar_animar("fade_out")

func tentar_animar(animacao: String):
	if animacao_em_curso:
		animacao_pendente = animacao
	else:
		animacao_em_curso = true
		if animacao == "fade_in":
			label.visible = true
		animation_player.play(animacao)

func _on_animation_finished(nome):
	animacao_em_curso = false
	
	if nome == "fade_out":
		label.visible = false
	
	if animacao_pendente != "":
		var proxima = animacao_pendente
		animacao_pendente = ""
		tentar_animar(proxima)

func _unhandled_input(event):
	if is_player_in_area and event.is_action_pressed("interact") and not carta_aberta:
		abrir_carta()
	elif carta_aberta and event.is_action_pressed("interact"):
		fechar_carta()

func abrir_carta():
	var carta_ui = preload("res://UI/game/CartaUI.tscn").instantiate()
	carta_ui.name = "CartaUI"
	carta_ui.get_node("TextHbox/MarginContainer/Text").text = text
	carta_ui.get_node("TitleHbox/MarginContainer/MarginContainer/Title").text = title
	if tema == "Verde":
		print("teste")
		carta_ui.get_node("ColorRect").color = "#417446"
		carta_ui.get_node("TitleHbox/MarginContainer/NinePatchRect").texture = preload("res://Sprites/UI/DialogTextBox/Verde/dialog-text-48x48-verde.png")

	carta_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	
	get_tree().root.add_child(carta_ui)

	GlobalVariables.controlsDisabled = true
	carta_aberta = true

func fechar_carta():
	var carta_ui = get_tree().root.get_node("CartaUI")
	if carta_ui:
		carta_ui.queue_free()
	GlobalVariables.controlsDisabled = false
	carta_aberta = false
