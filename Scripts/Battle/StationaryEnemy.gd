extends CharacterBody2D

signal defeated # Tambahkan signal ini

var enemy_bullet_scene = preload("res://Scenes/map/EnemyBullet.tscn")
var hp: float = 60.0
@onready var health_bar = $HealthBar

func _ready():
	add_to_group("enemy")
	health_bar.max_value = hp
	health_bar.value = hp

func take_damage(amount: float):
	hp -= amount
	health_bar.value = hp
	if hp <= 0:
		defeated.emit() # Lapor kalau mati
		queue_free()

func _on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var b = enemy_bullet_scene.instantiate()
		get_parent().add_child(b)
		b.global_position = self.global_position
		var aim_direction = (player.global_position - global_position).normalized()
		b.direction = aim_direction
		b.rotation = aim_direction.angle()
