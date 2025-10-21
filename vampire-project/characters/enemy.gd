extends CharacterBody2D
class_name Villager

@export var speed: float = 120.0
@export var chase_speed: float = 240.0
@export var attack_interval: float = 1.0
@export var attack_damage: int = 10
@export var max_health: int = 100

const SOUL_SCENE = preload("res://Enemy fragments/soul_fragment.tscn")
const BLOOD_SCENE = preload("res://Enemy fragments/blood_packages.tscn")

var roam_dir: Vector2 = Vector2.ZERO
var player: Node = null
var dead: bool = false
var health: int = max_health
var last_hit_type: String = ""   # last attcak version

# Timers
var directionTimer: Timer
var attackTimer: Timer

@onready var sprite = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("enemies")

	# --- Roaming direction timer ---
	directionTimer = $Timer
	directionTimer.wait_time = 2.0
	directionTimer.start()
	directionTimer.timeout.connect(_on_Timer_timeout)

	# --- Attack timer ---
	attackTimer = Timer.new()
	attackTimer.wait_time = attack_interval
	attackTimer.one_shot = false
	attackTimer.autostart = false
	add_child(attackTimer)
	attackTimer.timeout.connect(_on_attack_timer_timeout)

	# Connect detection areas
	$DetectionArea.body_entered.connect(_on_chase_area_body_entered)
	$DetectionArea.body_exited.connect(_on_chase_area_body_exited)
	$AttackArea.body_entered.connect(_on_attack_area_body_entered)
	$AttackArea.body_exited.connect(_on_attack_area_body_exited)


func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
	elif player:
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * chase_speed
	else:
		velocity = roam_dir * speed

	move_and_collide(velocity * delta)


# --- Roaming ---
func _on_Timer_timeout() -> void:
	if not player:
		var dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.ZERO]
		roam_dir = dirs[randi() % dirs.size()]


# --- Chase Area ---
func _on_chase_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body

func _on_chase_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null


# --- Attack Area ---
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body == player:
		attackTimer.start()

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == player:
		attackTimer.stop()


# --- Attack ---
func _on_attack_timer_timeout() -> void:
	if player and player.is_inside_tree():
		if "blood" in player:
			player.blood = max(player.blood - attack_damage, 0)
			if player.blood_meter:
				player.blood_meter.value = player.blood


# --- Damage & Death Handling ---
func take_damage(amount: int, attack_type := "bite") -> void:   
	if dead:
		return
	last_hit_type = attack_type
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	dead = true
	velocity = Vector2.ZERO
	_drop_loot()   
	queue_free()

# --- Drop logic ---
func _drop_loot() -> void:
	if last_hit_type == "bite":
		if SOUL_SCENE:
			var soul = SOUL_SCENE.instantiate()
			soul.global_position = global_position
			get_parent().add_child(soul)
	elif last_hit_type == "claw":
		
		if BLOOD_SCENE:
			var offsets = [
				Vector2(-24, -16),  
				Vector2(24, -8),    
				Vector2(0, 24)      
			]
			for offset in offsets:
				var blood = BLOOD_SCENE.instantiate()
				blood.global_position = global_position + offset + Vector2(randf_range(-4, 4), randf_range(-4, 4))
				get_parent().add_child(blood)
