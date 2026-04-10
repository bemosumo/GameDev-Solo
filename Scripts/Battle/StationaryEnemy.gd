extends CharacterBody2D

# Pastikan alamat ini sama dengan letak file peluru musuh lu
var enemy_bullet_scene = preload("res://Scenes/map/EnemyBullet.tscn") 
var hp: float = 20.0 # Darah Kroco

func _ready():
	add_to_group("enemy") # Tambahin baris ini

# Panggil otomatis dari Signal Timer tiap 1 detik
func _on_timer_timeout():
	# 1. Cari target (Player)
	var player = get_tree().get_first_node_in_group("player")
	
	# 2. Kalau Player ketemu, tembak!
	if player:
		var b = enemy_bullet_scene.instantiate()
		get_parent().add_child(b)
		b.global_position = self.global_position
		
		# 3. Hitung arah sudut dari musuh ke player
		var aim_direction = (player.global_position - global_position).normalized()
		
		# 4. Arahkan peluru
		b.direction = aim_direction
		b.rotation = aim_direction.angle() # Bikin moncong peluru muter


func take_damage(amount: float):
	hp -= amount
	if hp <= 0:
		queue_free() # Kroco meledak, tapi game tetep jalan
