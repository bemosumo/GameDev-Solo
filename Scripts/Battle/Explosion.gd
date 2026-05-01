extends Sprite2D

func _ready():
	# Biar posisi/rotasi ledakannya agak random tiap kali muncul
	rotation_degrees = randf_range(0, 360)
	
	# Mulai dari ukuran kecil
	scale = Vector2(0.5, 0.5)
	
	var tween = create_tween()
	
	# DURASI DITAMBAH JADI 0.8 DETIK, SKALA JADI 6.0
	tween.tween_property(self, "scale", Vector2(6.0, 6.0), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# FADE OUT JUGA DI-SET JADI 0.8 DETIK BIAR BARENGAN
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.8)
	
	# Kalau udah kelar memudar, langsung hapus nodenya
	tween.tween_callback(queue_free)
