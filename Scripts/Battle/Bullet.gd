extends Area2D

var speed: float = 700.0
var direction: Vector2 = Vector2.UP

func _process(delta):
	# Peluru gerak bebas sesuai 'direction'
	position += direction * speed * delta
	
	# Hapus peluru kalau udah keluar dari segala batas layar (atas/bawah/kiri/kanan)
	if position.x < -200 or position.x > 1500 or position.y < -200 or position.y > 1000:
		queue_free()

func _on_body_entered(body):
	# Cek apakah yang ditabrak itu musuh
	if body.is_in_group("enemy"):
		
		# Kasih damage ke musuh
		if body.has_method("take_damage"):
			var damage_peluru = GlobalData.get_final_damage()
			body.take_damage(damage_peluru)
		
		# Hancurkan peluru kuning ini biar gak tembus ke belakang musuh
		queue_free()
