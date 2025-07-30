extends Node2D

@onready var tilemap1 = $TileMap1
@onready var tilemap2 = $TileMap2
var active_tilemap = 1
var isChanging = false
func _process(delta):
	if Input.is_action_just_pressed("time_change") and !isChanging: 
		toggle_tilemap()

func toggle_tilemap():
	if active_tilemap == 1:
		isChanging = true
		active_tilemap = 2
		tilemap2.visible = true
		$TileMap2/Layer1.collision_enabled = true
		await get_tree().create_timer(0.4).timeout
		tilemap1.visible = false
		$TileMap1/TileMapLayer.collision_enabled = false
		isChanging = false
	else:
		isChanging = true
		$TileMap1/TileMapLayer.collision_enabled = true
		tilemap1.visible = true
		await get_tree().create_timer(0.4).timeout
		tilemap2.visible = false
		$TileMap2/Layer1.collision_enabled = false
		active_tilemap = 1
		isChanging = false
