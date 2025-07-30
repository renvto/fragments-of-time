extends CharacterBody2D

const SPEED = 125.0
const ACCELERATION = 1000.0
const DECELERATION = 1400.0
const AIR_ACCELERATION = 800.0
const AIR_DECELERATION = 600.0
const AIR_CONTROL = 1.2

const JUMP_VELOCITY = -290.0
const JUMP_BUFFER_TIME = 0.15
const COYOTE_TIME = 0.1
const MAX_JUMPS = 1
const WALL_JUMP_VELOCITY = Vector2(250.0, -310.0)
const WALL_SLIDE_SPEED = 40.0
const WALL_SLIDE_RELEASE_SPEED = 60.0 

const FAST_FALL_MULTIPLIER = 1.5
const GRAVITY = 800.0
const GRAVITY_MULTIPLIER_FALLING = 1.1
const GRAVITY_MULTIPLIER_JUMP_RELEASE = 1.5
const WALL_JUMP_GRAVITY_DELAY = 0.25 

const DASH_SPEED = 300.0
const DASH_DURATION = 0.15
const DASH_COOLDOWN = 0.3

const ATTACK_DURATION = 0.3
const ATTACK_COOLDOWN = 0.2

const MAX_STAMINA = 100.0
const WALL_JUMP_STAMINA_COST = 20.0  

const WALL_STICK_TIME = 0.5  
const WALL_JUMP_INPUT_GRACE_TIME = 0.2  

enum PlayerState {IDLE, WALKING_RIGHT, WALKING_LEFT, JUMPING, FALLING, WALL_SLIDE_RIGHT, WALL_SLIDE_LEFT, DASHING, WALL_JUMPING, ATTACKING}

var current_state = PlayerState.IDLE
var state_timer = 0.0
const STATE_CHANGE_DELAY = 0.04

var jumps_made = 0
var jump_buffer_timer = 0.0
var coyote_time_remaining = 0.0
var wall_jump_grace_timer = 0.0

var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = Vector2.ZERO
var is_dashing = false
var has_dashed = false

var is_attacking = false
var is_dead = false
var attack_animation_active = false
var attack_cooldown_timer = 0.0

var is_wall_sliding = false
var was_wall_sliding = false
var last_wall_normal = Vector2.ZERO
var wall_jump_direction = 0.0
var wall_stick_timer = 0.0  
var wall_jump_input_grace_timer = 0.0 
var last_wall_direction = 0.0  

var current_stamina = MAX_STAMINA
var consecutive_wall_jumps = 0

var has_air_jump_after_wall_jump = false

var last_pressed_direction = 0.0

var wall_slide_input_direction = 0.0

var virtual_button_pressed = false
var virtual_button_direction = 0.0

var force_wall_stick = false

@onready var sprite = $Sprite2D
@onready var anim_player = $AnimationPlayer
@onready var main_collision = $MainCollision  

@onready var collision_andar_direita = $AndarDireita
@onready var collision_andar_esquerda = $AndarEsquerda
@onready var collision_wallslide_direita = $WallSlideDireita
@onready var collision_wallslide_esquerda = $WallSlideEsquerda
@onready var idle: CollisionShape2D = $Idle

func handle_dash(_delta: float) -> void:
	velocity = dash_direction * DASH_SPEED

func _ready():
	collision_andar_direita.disabled = true
	collision_andar_esquerda.disabled = true
	collision_wallslide_direita.disabled = true
	collision_wallslide_esquerda.disabled = true
	idle.disabled = true
	
	main_collision.disabled = false
	
	anim_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

func _physics_process(delta: float) -> void:
	if GlobalVariables.controlsDisabled:
		return
		
	update_timers(delta)
	
	if state_timer > 0:
		state_timer -= delta
	
	if attack_animation_active:
		apply_gravity(delta)
		move_and_slide()
		return
		
	if is_dashing:
		handle_dash(delta)
		set_player_state(PlayerState.DASHING)
		move_and_slide()
		return
		
	was_wall_sliding = is_wall_sliding
	check_wall_slide()
	
	if is_wall_sliding:
		jumps_made = 0
		
		if current_stamina >= WALL_JUMP_STAMINA_COST:
			has_air_jump_after_wall_jump = true
		else:
			has_air_jump_after_wall_jump = false
	
	check_cancel_virtual_button()
	
	handle_jump_buffer()
	
	apply_gravity(delta)
	
	if force_wall_stick and wall_stick_timer > 0:
		if last_wall_direction > 0: 
			velocity.x = 20 
		else: 
			velocity.x = -20 
		
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
	else:
		handle_horizontal_movement(delta)
	
	handle_jump_input()
	
	handle_dash_input()
	
	handle_attack_input()
	
	update_state_and_animation()
	
	move_and_slide()
	
	if is_on_floor():
		if jumps_made > 0 or consecutive_wall_jumps > 0:
			current_stamina = MAX_STAMINA
		
		jumps_made = 0
		has_dashed = false
		coyote_time_remaining = COYOTE_TIME
		
		consecutive_wall_jumps = 0
		has_air_jump_after_wall_jump = false  
	elif coyote_time_remaining > 0:
		coyote_time_remaining -= delta

func check_cancel_virtual_button() -> void:
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("dash") or Input.is_action_just_pressed("attack"):
		virtual_button_pressed = false
		force_wall_stick = false 

func update_timers(delta: float) -> void:
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
		
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
		
	if dash_timer > 0:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
			
	if wall_jump_grace_timer > 0:
		wall_jump_grace_timer -= delta
		
	# Novos timers
	if wall_stick_timer > 0:
		wall_stick_timer -= delta
		if wall_stick_timer <= 0:
			force_wall_stick = false
		
	if wall_jump_input_grace_timer > 0:
		wall_jump_input_grace_timer -= delta

func set_player_state(new_state):
	if attack_animation_active:
		return
		
	if new_state == PlayerState.WALL_JUMPING:
		current_state = new_state
		update_collision_shape()  
		state_timer = 0  
	elif state_timer <= 0 or new_state == PlayerState.DASHING or new_state == PlayerState.ATTACKING:
		current_state = new_state
		state_timer = STATE_CHANGE_DELAY
		update_collision_shape()

func update_collision_shape():
	var target_shape = null
	
	match current_state:
		PlayerState.ATTACKING:
			if sprite.flip_h:
				target_shape = collision_andar_esquerda
			else:
				target_shape = collision_andar_direita
		PlayerState.DASHING, PlayerState.WALL_JUMPING:
			if dash_direction.x >= 0 or wall_jump_direction >= 0:
				target_shape = collision_andar_direita
			else:
				target_shape = collision_andar_esquerda
		PlayerState.WALL_SLIDE_RIGHT:
			target_shape = collision_wallslide_direita
		PlayerState.WALL_SLIDE_LEFT:
			target_shape = collision_wallslide_esquerda
		PlayerState.WALKING_RIGHT:
			if not sprite.flip_h:
				target_shape = collision_andar_direita
			else:
				target_shape = collision_andar_esquerda
		PlayerState.IDLE:
			target_shape = idle
		PlayerState.WALKING_LEFT:
			target_shape = collision_andar_esquerda
		PlayerState.JUMPING, PlayerState.FALLING:
			if sprite.flip_h:
				target_shape = collision_andar_esquerda
			else:
				target_shape = collision_andar_direita
	
	if target_shape != null:
		main_collision.shape = target_shape.shape.duplicate()
		main_collision.position = target_shape.position
		main_collision.rotation = target_shape.rotation
		main_collision.scale = target_shape.scale
		main_collision.one_way_collision = target_shape.one_way_collision
		main_collision.one_way_collision_margin = target_shape.one_way_collision_margin

func check_wall_slide() -> void:
	is_wall_sliding = false
	
	if not is_on_floor() and is_on_wall():
		var wall_normal = get_wall_normal()
		
		if (Input.is_action_pressed("move_right") or (virtual_button_pressed and virtual_button_direction > 0)) and wall_normal.x < 0:
			is_wall_sliding = true
			last_wall_normal = wall_normal
			last_wall_direction = 1.0  #
			wall_slide_input_direction = 1.0
			
			if Input.is_action_just_released("move_right"):
				virtual_button_pressed = true
				virtual_button_direction = 1.0
				force_wall_stick = true
				wall_stick_timer = WALL_STICK_TIME
			
			velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
			set_player_state(PlayerState.WALL_SLIDE_RIGHT)
			
		elif (Input.is_action_pressed("move_left") or (virtual_button_pressed and virtual_button_direction < 0)) and wall_normal.x > 0:
			is_wall_sliding = true
			last_wall_normal = wall_normal
			last_wall_direction = -1.0  
			wall_slide_input_direction = -1.0
			
			if Input.is_action_just_released("move_left"):
				virtual_button_pressed = true
				virtual_button_direction = -1.0
				force_wall_stick = true
				wall_stick_timer = WALL_STICK_TIME
			
			velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
			set_player_state(PlayerState.WALL_SLIDE_LEFT)
	
	if was_wall_sliding and !is_wall_sliding:
		wall_jump_input_grace_timer = WALL_JUMP_INPUT_GRACE_TIME
		state_timer = STATE_CHANGE_DELAY * 2
		if !force_wall_stick:
			virtual_button_pressed = false  
		
	# Se começamos a wall slide agora
	if !was_wall_sliding and is_wall_sliding:
		wall_stick_timer = WALL_STICK_TIME

func handle_jump_buffer() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var gravity_multiplier = 1.0
		
		if wall_jump_grace_timer > 0:
			gravity_multiplier = 0.5
		elif velocity.y > 0:
			gravity_multiplier = GRAVITY_MULTIPLIER_FALLING
		elif Input.is_action_just_released("jump") and velocity.y < 0:
			gravity_multiplier = GRAVITY_MULTIPLIER_JUMP_RELEASE
			
		if Input.is_action_pressed("move_down"):
			gravity_multiplier *= FAST_FALL_MULTIPLIER
			
		velocity.y += GRAVITY * gravity_multiplier * delta

func handle_horizontal_movement(delta: float) -> void:
	var direction = get_movement_direction()
	
	if direction != 0:
		var accel = ACCELERATION if is_on_floor() else AIR_ACCELERATION
		
		var control_multiplier = AIR_CONTROL
		if current_state == PlayerState.WALL_JUMPING:
			if (wall_jump_direction < 0 and direction > 0) or (wall_jump_direction > 0 and direction < 0):
				control_multiplier = AIR_CONTROL * 1.8  
			else:
				control_multiplier = AIR_CONTROL * 1.4  
		
		velocity.x = move_toward(velocity.x, direction * SPEED, accel * control_multiplier * delta)
		
		if not attack_animation_active:
			sprite.flip_h = direction < 0
	else:
		var decel = DECELERATION if is_on_floor() else AIR_DECELERATION
		velocity.x = move_toward(velocity.x, 0, decel * delta)

func get_movement_direction() -> float:
	var direction := 0.0
	
	if Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right"):
		direction = last_pressed_direction
	else:
		var real_direction = Input.get_axis("move_left", "move_right")
		
		if real_direction != 0:
			direction = real_direction
			if !is_wall_sliding:  
				virtual_button_pressed = false
				force_wall_stick = false
		elif virtual_button_pressed:
			direction = virtual_button_direction
	
	if Input.is_action_just_pressed("move_left"):
		last_pressed_direction = -1.0
	elif Input.is_action_just_pressed("move_right"):
		last_pressed_direction = 1.0
	
	return direction

func handle_jump_input() -> void:
	if (is_wall_sliding or wall_jump_input_grace_timer > 0) and Input.is_action_just_pressed("jump"):
		if current_stamina >= WALL_JUMP_STAMINA_COST:
			perform_wall_jump()
		return
	
	if jump_buffer_timer > 0:
		if is_on_floor() or coyote_time_remaining > 0:
			print("c")
			velocity.y = JUMP_VELOCITY
			jump_buffer_timer = 0
			coyote_time_remaining = 0
		elif has_air_jump_after_wall_jump:
			print("a")
			velocity.y = JUMP_VELOCITY
			jump_buffer_timer = 0
			has_air_jump_after_wall_jump = false  
		elif jumps_made < MAX_JUMPS:
			if current_stamina >= WALL_JUMP_STAMINA_COST:
				jumps_made += 1
				velocity.y = JUMP_VELOCITY
				jump_buffer_timer = 0
		
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

func perform_wall_jump():
	if is_wall_sliding:
		velocity.x = last_wall_normal.x * WALL_JUMP_VELOCITY.x
	else:
		velocity.x = -last_wall_direction * WALL_JUMP_VELOCITY.x
		
	velocity.y = WALL_JUMP_VELOCITY.y  
	wall_jump_direction = -last_wall_normal.x if is_wall_sliding else last_wall_direction
	wall_jump_grace_timer = WALL_JUMP_GRAVITY_DELAY
	
	if consecutive_wall_jumps >= 2:
		velocity.x *= (1.0 + (consecutive_wall_jumps * 0.05)) 
	
	has_air_jump_after_wall_jump = true
	
	jumps_made = 0
	
	set_player_state(PlayerState.WALL_JUMPING)

	current_stamina -= WALL_JUMP_STAMINA_COST
	consecutive_wall_jumps += 1
	
	wall_stick_timer = 0.0
	wall_jump_input_grace_timer = 0.0
	
	virtual_button_pressed = false
	force_wall_stick = false

func handle_dash_input() -> void:
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0 and not has_dashed:
		var dash_dir = Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		)
		
		if dash_dir == Vector2.ZERO:
			dash_dir = Vector2(-1, 0) if sprite.flip_h else Vector2(1, 0)
		
		dash_direction = dash_dir.normalized()
		is_dashing = true
		has_dashed = true
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN
		
		virtual_button_pressed = false
		force_wall_stick = false
		
		velocity = Vector2.ZERO

func handle_attack_input() -> void:
	if Input.is_action_just_pressed("attack") and attack_cooldown_timer <= 0 and not attack_animation_active:
		is_attacking = true
		attack_animation_active = true
		attack_cooldown_timer = ATTACK_COOLDOWN
		set_player_state(PlayerState.ATTACKING)
		play_animation("hit")
		
		virtual_button_pressed = false
		force_wall_stick = false
		
		velocity.x *= 0.5

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "hit":
		attack_animation_active = false
		is_attacking = false
	elif anim_name == "death":
		is_dead = false
		attack_animation_active = false
		GlobalVariables.controlsDisabled = false

func update_state_and_animation() -> void:
	if attack_animation_active:
		return  
	elif is_dashing:
		play_animation("dash")
		set_player_state(PlayerState.DASHING)
	elif current_state == PlayerState.WALL_JUMPING and wall_jump_grace_timer > 0:
		play_animation("jump")
	elif is_wall_sliding:
		play_animation("wall_slide")
	elif not is_on_floor():
		if velocity.y < 0:
			play_animation("jump")
			if current_state != PlayerState.WALL_JUMPING:
				set_player_state(PlayerState.JUMPING)
		else:
			play_animation("fall")
			if current_state != PlayerState.WALL_JUMPING:
				set_player_state(PlayerState.FALLING)
	elif abs(velocity.x) > 10:
		play_animation("walking")
		if velocity.x > 0:
			set_player_state(PlayerState.WALKING_RIGHT)
		else:
			set_player_state(PlayerState.WALKING_LEFT)
	else:
		play_animation("idle")
		set_player_state(PlayerState.IDLE)

func play_animation(anim_name: String) -> void:
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	attack_animation_active = true
	play_animation("death")
