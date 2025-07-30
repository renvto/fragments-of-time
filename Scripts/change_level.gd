extends Area2D

@export var destinationPathScene : String

func _on_body_entered(body):
	get_tree().change_scene_to_file(destinationPathScene)
