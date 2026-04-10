extends Area2D

var speed: float = 700.0

func _process(delta):
	position.x += speed * delta
	
	if position.x > 2000:
		queue_free()

func _on_body_entered(body):
	# Cek apakah yang ditabrak itu musuh
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			# Panggil fungsi damage lu yang bisa dapet buff/debuff Ammo!
			var damage_peluru = GlobalData.get_final_damage()
			body.take_damage(damage_peluru)
		# Cek apakah musuh itu adalah sang Bos
		# (PENTING: Pastikan nama node bos lu di layar BattlePhase itu beneran "Boss")
		if body.name == "Boss":
			var arena = body.get_parent()
			if arena.has_method("enemy_defeated"):
				arena.enemy_defeated() # Lapor kalau kita menang!
		
		# Hancurkan musuhnya (Berlaku buat Bos maupun Kroco Statis)
		body.queue_free()
		
		# Hancurkan peluru ini biar gak tembus ke belakang
		queue_free()
