extends Area2D
class_name EnemyBase # Penting biar script lain bisa ngewarisin ini

signal defeated

@export var hp: int = 3
@export var speed: int = 50
@export var bullet_scene: PackedScene = preload("res://Scenes/map/EnemyBullet.tscn")

@onready var shoot_timer = $ShootTimer
@onready var muzzle = $Muzzle

func _ready():
	# Sambungin timer buat nembak
	if shoot_timer:
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)

func _process(delta):
	# Musuh turun perlahan
	position.y += speed * delta
	if position.y > 800: # Kalau lewat layar bawah, hapus
		queue_free()

func _on_shoot_timer_timeout():
	shoot()

func shoot():
	if bullet_scene and muzzle:
		var b = bullet_scene.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = muzzle.global_position

func take_damage(amount):
	hp -= amount
	if hp <= 0:
		die()

func die():
	defeated.emit()
	queue_free()

# Pas kena peluru Player
func _on_area_entered(area):
	if area.name.contains("Bullet"): # Ganti dengan deteksi peluru lu (misal pakai grup)
		take_damage(1)
		area.queue_free()
