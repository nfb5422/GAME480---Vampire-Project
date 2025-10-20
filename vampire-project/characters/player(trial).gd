extends CharacterBody2D
@onready var bite_area = $BiteArea 
@onready var bite_sprite = $BiteArea/BiteSprite # Added for bite
@export var bite_damage := 20
@export var speed = 400
@export var dash_speed = 5000
@export var dash_duration := 0.2
@export var dash_cooldown := 1.0

# Sprites
@onready var sprite_down = $SpriteDown
@onready var sprite_up = $SpriteUp
@onready var sprite_side = $SpriteSide
# Remember facing direction
var last_facing := Vector2.DOWN
var dash_timer := 0.0
var cooldown_timer := 0.0
var is_dashing := false
var dash_direction := Vector2.ZERO
var dash_hit_enemies := []  # Track which enemies were hit this dash
var soul_count: int = 0
#blood meter
@export var max_blood := 100
var blood := max_blood
@export var dash_cost := 25

@onready var blood_meter = get_tree().root.get_node("/root/Node2D/CanvasLayer/ProgressBar") 

	
func _ready():
	# Hide bite sprite initially
	bite_sprite.visible = false
	# Connect animation finished signal
	bite_sprite.animation_finished.connect(_on_bite_animation_finished)
	
func _physics_process(delta):
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * speed
	if input_direction != Vector2.ZERO:
		$BiteArea.position = input_direction.normalized() * 16
		$BiteArea.rotation = input_direction.angle()
	_update_sprite_direction(input_direction)
	if Input.is_action_just_pressed("Sprint"):
		speed = 600
	if Input.is_action_just_released("Sprint"):
		speed = 400

	if is_dashing:
		velocity = dash_direction * dash_speed
		dash_timer -= delta
				# Enable bite area during dash
		$BiteArea.monitoring = true

		# Damage enemies
		for body in $BiteArea.get_overlapping_bodies():
			if body.is_in_group("enemies") and body not in dash_hit_enemies:
				if body.has_method("take_damage"):
					body.take_damage(20)
					dash_hit_enemies.append(body)
		if dash_timer <= 0.0:
			is_dashing = false
	else:
		velocity = input_direction * speed
		
		# Start dash if spacebar pressed and cooldown ready
		if Input.is_action_just_pressed("dash") and cooldown_timer <= 0.0 and blood_meter.value >= dash_cost:
			is_dashing = true
			dash_direction = input_direction.normalized()
			dash_timer = dash_duration
			cooldown_timer = dash_cooldown
			blood -= dash_cost
			blood_meter.value = blood
	
		if cooldown_timer > 0.0:
			cooldown_timer -= delta
	if Input.is_action_just_pressed("bite"):  # Define bite action in Input Map
		_do_bite(input_direction)

	move_and_slide()
func _do_bite(direction: Vector2):
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT  # Default forward
	bite_area.position = direction.normalized() * 16  # Offset in front of player
	bite_area.rotation = direction.angle()
	bite_area.player = self
	bite_area.bite_damage = bite_damage
	bite_area.monitoring = true
		# Play animation
	bite_sprite.visible = true
	bite_sprite.play("default")
	  # Ensure you have an animation called "bite" in the AnimatedSprite2D

	# Turn the sprite toward the direction faced
	bite_sprite.flip_h = direction.x < 0
	bite_sprite.rotation = direction.angle()

	# Disable monitoring after a short delay
	await get_tree().create_timer(0.1).timeout
	bite_area.monitoring = false
	
func _update_sprite_direction(input_direction: Vector2):
	# Hide all sprites first
	sprite_down.visible = false
	sprite_up.visible = false
	sprite_side.visible = false

	var facing = input_direction if input_direction != Vector2.ZERO else last_facing

	if facing.y < -0.5:
		sprite_up.visible = true

	elif facing.y > 0.5:
		sprite_down.visible = true
	elif facing.x != 0:
		sprite_side.visible = true
		sprite_side.flip_h = facing.x < 0
	else:
		sprite_down.visible = true
func _on_bite_animation_finished():
	bite_sprite.stop()
	bite_sprite.visible = false

func add_soul(amount: int = 1):	
	soul_count += amount	
	update_soul_ui()  # HUD güncelleme fonksiyonu

var soul_label: Label = null  # HUD referansı cache'lenecek

func _cache_hud():	
	# HUD sahnesindeki SoulLabel'i bulur ve saklar		
	soul_label = get_tree().get_root().find_child("SoulLabel", true, false)

func update_soul_ui():
	# Eğer SoulLabel daha bulunmadıysa, bir kere daha ara	
		if soul_label == null:
			_cache_hud()
		if soul_label:
			soul_label.text = "Soul: %d" % soul_count
