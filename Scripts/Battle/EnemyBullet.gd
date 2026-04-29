extends Area2D

var speed: float = 350.0
var direction: Vector2 = Vector2.LEFT # Arah default, nanti bakal ditimpa sama bos

func _process(delta):
	# Terbang lurus sesuai sudut/arah yang diperintahkan Bos
	position += direction * speed * delta
	
	# Hapus peluru kalau udah jauh keluar layar (biar RAM gak bocor)
	if position.x < -200 or position.x > 1500 or position.y < -200 or position.y > 1000:
		queue_free()
func _on_body_entered(body):
	# Kalau nabrak player, kasih damage!
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(10.0) # Peluru musuh ngasih 15 damage
		queue_free() # Peluru merah hancur
