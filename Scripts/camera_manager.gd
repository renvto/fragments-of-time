extends Node

@export var player: CharacterBody2D
@export var Camera_Zone0: PhantomCamera2D
@export var Camera_Zone1: PhantomCamera2D
@export var Camera_Zone2: PhantomCamera2D
@export var Camera_Zone3: PhantomCamera2D

var current_camera_zone: int = 0
var movement_distance: float = 15.0
var movement_duration: float = 0.2

func freeze_player():
	player.set_physics_process(false)
	await get_tree().create_timer(1.0).timeout
	player.set_physics_process(true)

func disable_player_controls():
	GlobalVariables.controlsDisabled = true
		
func enable_player_controls():
	GlobalVariables.controlsDisabled = false
	
func update_current_zone(body, zone_a, zone_b):
	if body == player:
		match current_camera_zone:
			zone_a:
				current_camera_zone = zone_b
			zone_b:
				current_camera_zone = zone_a
		freeze_player()
		update_camera()

func update_camera():
	print("Camera Zone: ", current_camera_zone)
	var cameras = [Camera_Zone0, Camera_Zone1]
	for camera in cameras:
		if camera != null:
			camera.priority = 0
	match current_camera_zone:
		0:
			Camera_Zone0.priority = 1
		1:
			Camera_Zone1.priority = 1
		2:
			Camera_Zone2.priority = 1
		3:
			Camera_Zone3.priority = 1
	move_player_forward()

func move_player_forward():
	var direction = Vector2.ZERO

	if player.velocity.x > 0:
		direction.x = 1  
	elif player.velocity.x < 0:
		direction.x = -1 

	if direction != Vector2.ZERO:
		start_smooth_movement(direction)

func start_smooth_movement(direction):
	var total_moved: float = 0.0
	var step_size: float = direction.x * (movement_distance / (movement_duration * 60))  

	for i in range(int(movement_distance)):
		player.position.x += step_size
		await get_tree().create_timer(1 / 60).timeout  
		total_moved += step_size

func _on_zone_01_body_entered(body):
	disable_player_controls()
	update_current_zone(body, 0, 1)
	enable_player_controls()

func _on_zone_12_body_entered(body):
	disable_player_controls()
	update_current_zone(body, 1, 2)
	enable_player_controls()

func _on_zone_23_body_entered(body):
	disable_player_controls()
	update_current_zone(body, 2, 3)
	enable_player_controls()

func _on_zone_34_body_entered(body):
	disable_player_controls()
	update_current_zone(body, 3, 4)
	enable_player_controls()
