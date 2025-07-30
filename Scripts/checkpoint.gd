extends Area2D
class_name Checkpoint

signal checkpoint_activated(checkpoint_id)

@export var visual_effect_scene: PackedScene
@export var activation_sound: AudioStream

var is_active: bool = false

func _ready():
	body_entered.connect(_on_checkpoint_body_entered)
	
	var chapter = GameManager.current_chapter
	var checkpoint_id = name
	
	if checkpoint_id in GameManager.get_unlocked_checkpoints(chapter):
		is_active = true
		_update_visual_state()

func _on_checkpoint_body_entered(body):
	GameManager.current_checkpoint_id = name
	if body.name != "Player" or is_active:
		return
	var chapter = GameManager.current_chapter
	var checkpoint_id = name

	GameManager.unlock_checkpoint(chapter, checkpoint_id)
	is_active = true
	
	_play_activation_effects()
	#_update_visual_state()
	
	checkpoint_activated.emit(checkpoint_id)

func _play_activation_effects():
	# Toca som se atribuído
	if activation_sound != null:
		var audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
		audio_player.stream = activation_sound
		
		audio_player.bus = "SFX" 
		
		audio_player.play()
		audio_player.finished.connect(func(): audio_player.queue_free())
	
	if visual_effect_scene != null:
		var effect = visual_effect_scene.instantiate()
		add_child(effect)
		if effect.has_method("play"):
			effect.play()

func _update_visual_state():
	if has_node("ActiveSprite") and has_node("InactiveSprite"):
		$ActiveSprite.visible = is_active
		$InactiveSprite.visible = !is_active
