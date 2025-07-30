extends Node

signal checkpoint_unlocked(chapter, checkpoint_id)
signal game_loaded
signal game_saved

const SAVE_PATH := "user://GameProgress.save"

var unlocked_checkpoints := {}
var current_checkpoint_id: String = "checkpoint_1"
var current_chapter: int = 1
var game_data := {}

func _ready():
	load_game_progress()

func get_unlocked_checkpoints(chapter: int) -> Array:
	var key = str(chapter)
	if unlocked_checkpoints.has(key):
		return unlocked_checkpoints[key]
	unlock_checkpoint(chapter, "checkpoint_1")
	return ["checkpoint_1"]

func unlock_checkpoint(chapter: int, checkpoint_id: String):
	var key = str(chapter)
	if not unlocked_checkpoints.has(key):
		unlocked_checkpoints[key] = []
	if checkpoint_id not in unlocked_checkpoints[key]:
		unlocked_checkpoints[key].append(checkpoint_id)
		checkpoint_unlocked.emit(chapter, checkpoint_id)
		save_game_progress()

func set_current_checkpoint(chapter: int, checkpoint_id: String):
	current_chapter = chapter
	current_checkpoint_id = checkpoint_id

func set_current_checkpoint_from_id(chapter_str: String, checkpoint_id: String):
	set_current_checkpoint(int(chapter_str), checkpoint_id)

func save_game_data(key: String, value):
	game_data[key] = value
	save_game_progress()

func get_game_data(key: String, default_value = null):
	return game_data.get(key, default_value)

func save_game_progress():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		print("ERRO: Falha ao abrir arquivo de save para escrita")
		return
		
	var save_data = {
		"unlocked_checkpoints": unlocked_checkpoints,
		"current_chapter": current_chapter,
		"current_checkpoint_id": current_checkpoint_id,
		"game_data": game_data
	}
	
	file.store_var(save_data)
	file.close()
	game_saved.emit()
	
	print("Jogo salvo com sucesso")

func load_game_progress():
	if not FileAccess.file_exists(SAVE_PATH):
		print("Nenhum arquivo de save encontrado, usando valores padrão")
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		print("ERRO: Falha ao abrir arquivo de save para leitura")
		return
		
	var save_data = file.get_var()
	file.close()

	if save_data == null:
		print("ERRO: Arquivo de save parece corrompido")
		return
		
	if save_data.has("unlocked_checkpoints"):
		unlocked_checkpoints = save_data["unlocked_checkpoints"]
	
	if save_data.has("current_chapter"):
		current_chapter = save_data["current_chapter"]
		
	if save_data.has("current_checkpoint_id"):
		current_checkpoint_id = save_data["current_checkpoint_id"]
		
	if save_data.has("game_data"):
		game_data = save_data["game_data"]
	
	game_loaded.emit()
	print("Jogo carregado com sucesso")

func reset_game_progress():
	unlocked_checkpoints = {}
	current_chapter = 1
	current_checkpoint_id = "checkpoint_1"
	game_data = {}
	save_game_progress()
	print("Progresso do jogo resetado")
