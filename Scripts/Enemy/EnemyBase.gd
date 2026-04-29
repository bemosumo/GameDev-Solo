extends CharacterBody2D
class_name EnemyBase

signal defeated

@export var hp: float = 60.0
@export var speed: float = 200.0
var enemy_bullet_scene = preload("res://Scenes/map/EnemyBullet.tscn")

@onready var health_bar = $HealthBar
@onready var shoot_timer = $ShootTimer
@onready var muzzle = $Muzzle

var can_shoot = false 

func _ready():
	add_to_group("enemy")
	scale = Vector2(0.4, 0.4) 
	
	if health_bar:
		health_bar.max_value = hp
		health_bar.value = hp
		
	if shoot_timer:
		shoot_timer.timeout.connect(_on_timer_timeout)

func take_damage(amount: float):
	hp -= amount
	if health_bar:
		health_bar.value = hp
	if hp <= 0:
		defeated.emit()
		queue_free()

func _on_timer_timeout():
	if can_shoot:
		shoot()

# Mekanik ngincer player murni buatan lu
func shoot():
	var player = get_tree().get_first_node_in_group("player")
	if player and enemy_bullet_scene and muzzle:
		var b = enemy_bullet_scene.instantiate()
		get_parent().add_child(b)
		b.global_position = muzzle.global_position
		
		var aim_direction = (player.global_position - global_position).normalized()
		b.direction = aim_direction
		b.rotation = aim_direction.angle()
