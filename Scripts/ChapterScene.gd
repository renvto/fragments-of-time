extends Node2D
class_name ChapterScene

@export var chapter_number: int = 1
@export var chapter_title: String = "Capítulo sem Título"

func _ready():
	GlobalVariables.controlsDisabled = false
	GameManager.current_chapter = chapter_number
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	for checkpoint in $Checkpoints.get_children():
		if checkpoint is Checkpoint:
			checkpoint.checkpoint_activated.connect(_on_checkpoint_activated)
	
	call_deferred("spawn_player_at_checkpoint")

func _on_checkpoint_activated(checkpoint_id):
	print("Checkpoint ativado: " + checkpoint_id)

func spawn_player_at_checkpoint():
	var checkpoints = GameManager.get_unlocked_checkpoints(chapter_number)
	
	var checkpoint_name = GameManager.current_checkpoint_id
	
	if not $Checkpoints.has_node(checkpoint_name) and checkpoints.size() > 0:
		checkpoint_name = checkpoints[-1]
	
	if not $Checkpoints.has_node(checkpoint_name):
		checkpoint_name = "checkpoint_1"
		print("AVISO: Checkpoint solicitado não encontrado, usando o padrão")
	
	var spawn_point
	if GlobalVariables.hardcore == true:
		spawn_point = $Checkpoints.get_node("checkpoint_1")
	else:
		spawn_point = $Checkpoints.get_node(checkpoint_name)
	$Player.global_position = spawn_point.global_position
	
	print("Jogador com spawn no checkpoint: " + checkpoint_name)
