extends CharacterBody2D

signal defeated

var speed: float = 150.0
var target_pos: Vector2
var hp: float = 200.0 # Darah Bos

# Pastikan alamat scene peluru musuh ini BENER sesuai tempat lu nyimpen EnemyBullet.tscn
var enemy_bullet_scene = preload("res://Scenes/map/EnemyBullet.tscn")

@onready var health_bar = $HealthBar

func _ready():
	add_to_group("enemy")
	
	# Inisialisasi bar sesuai HP saat ini
	health_bar.max_value = hp
	health_bar.value = hp
	
	# Kalau di Boss, panggil fungsi gerak acak juga
	if has_method("pick_new_random_position"):
		pick_new_random_position()

func take_damage(amount: float):
	hp -= amount
	# Update visual bar
	health_bar.value = hp
	
	print(name, " kena hit! Sisa HP: ", hp)
	
	if hp <= 0:
		defeated.emit()
		queue_free()

func pick_new_random_position():
	# Nentuin koordinat ngacak di SETENGAH LAYAR ATAS
	# X bisa dari ujung kiri ke kanan, Y tertahan di atas
	var random_x = randf_range(100, 1050) 
	var random_y = randf_range(50, 250) 
	target_pos = Vector2(random_x, random_y)

func _physics_process(_delta):
	# Kalau masih jauh dari titik tujuan, jalan terus!
	if global_position.distance_to(target_pos) > 10:
		# Cari tau arah menuju titik tujuan, lalu bergerak
		var move_direction = global_position.direction_to(target_pos)
		velocity = move_direction * speed
		move_and_slide()
	else:
		# Kalau udah nyampe tujuan, cari titik acak baru lagi
		pick_new_random_position()

# FUNGSI TEMBAK (Dipanggil otomatis sama Timer tiap 1.5 detik)
# FUNGSI TEMBAK BARBAR (Spread Shot 5 Arah)
func _on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		# 1. Cari arah tengah (lurus ke player)
		var base_direction = (player.global_position - global_position).normalized()
		var base_angle = base_direction.angle()
		
		# 2. Tembak 5 peluru sekaligus dalam bentuk kipas
		# Loop berjalan untuk nilai: -2, -1, 0, 1, 2
		for i in range(-2, 3): 
			var b = enemy_bullet_scene.instantiate()
			get_parent().add_child(b)
			b.global_position = self.global_position
			
			# 3. Miringkan sudut tembakan (15 derajat antar peluru)
			# deg_to_rad berfungsi mengubah derajat jadi radian (bahasa matematika Godot)
			var spread_angle = base_angle + (i * deg_to_rad(15))
			
			# 4. Ubah sudut baru tadi kembali menjadi arah (Vector2)
			var final_direction = Vector2(cos(spread_angle), sin(spread_angle))
			
			# 5. Arahkan pelurunya!
			b.direction = final_direction
			b.rotation = final_direction.angle()
