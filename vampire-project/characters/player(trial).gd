extends CharacterBody2D

@export var speed = 400
@export var dash_speed = 1000
@export var dash_duration := 0.2
@export var dash_cooldown := 1.0
var dash_timer := 0.0
var cooldown_timer := 0.0
var is_dashing := false
var dash_direction := Vector2.ZERO

	

func _physics_process(delta):
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * speed
	if Input.is_action_just_pressed("Sprint"):
		speed = 600
	if Input.is_action_just_released("Sprint"):
		speed = 400
	if is_dashing:
		velocity = dash_direction * dash_speed
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
	else:
		velocity = input_direction * speed
		
		# Start dash if spacebar pressed and cooldown ready
		if Input.is_action_just_pressed("dash") and cooldown_timer <= 0.0:
			is_dashing = true
			dash_direction = input_direction.normalized()
			dash_timer = dash_duration
			cooldown_timer = dash_cooldown
	
		if cooldown_timer > 0.0:
			cooldown_timer -= delta
	

	move_and_slide()
