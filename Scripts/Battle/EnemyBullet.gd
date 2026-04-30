extends Area2D

@export var speed: float = 400.0
var direction: Vector2 = Vector2.DOWN # Default ke bawah

func _process(delta):
	# Bakal gerak sesuai arah yang diset dari musuh
	position += direction * speed * delta 
	
	# Hapus peluru kalau keluar layar (sesuain ukurannya)
	if position.y > 800 or position.y < -100 or position.x < -100 or position.x > 1250:
		queue_free()

func _on_body_entered(body):
	# Cek apakah yang ditabrak itu ada di grup "player"
	if body.is_in_group("player"):
		# Kasih damage ke player (misal damage-nya 10)
		body.take_damage(10.0) 
		# Hancurkan peluru musuhnya
		queue_free()
