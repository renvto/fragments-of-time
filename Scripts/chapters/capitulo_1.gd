extends ChapterScene

func _ready():
	chapter_number = 1
	chapter_title = "O que aconteceu?"
	
	super._ready()
	
	pass

func _on_checkpoint_activated(checkpoint_id):
	super._on_checkpoint_activated(checkpoint_id)
	
	match checkpoint_id:
		"checkpoint_1":
			print("Primeiro checkpoint do capítulo 1 ativado!")
		"checkpoint_2":
			print("Segundo checkpoint do capítulo 1 ativado!")


func _on_area_2d_body_entered(body: Node2D) -> void:
		super._ready()
