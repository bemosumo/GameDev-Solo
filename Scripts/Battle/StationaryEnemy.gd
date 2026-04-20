extends CharacterBody2D

var enemy_bullet_scene = preload("res://Scenes/map/EnemyBullet.tscn")
var hp: float = 60.0

@onready var health_bar = $HealthBar

func _ready():
	add_to_group("enemy")
	
	# Inisialisasi bar sesuai HP saat ini
	health_bar.max_value = hp
	health_bar.value = hp

func take_damage(amount: float):
	hp -= amount
	# Update visual bar
	health_bar.value = hp
	
	print(name, " kena hit! Sisa HP: ", hp)
	
	if hp <= 0:
		if name == "Boss":
			var arena = get_parent()
			if arena.has_method("enemy_defeated"):
				arena.enemy_defeated()
		queue_free()

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
