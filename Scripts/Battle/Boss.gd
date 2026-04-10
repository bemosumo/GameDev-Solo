extends CharacterBody2D

var speed: float = 150.0
var target_pos: Vector2 
var hp: float = 50.0 # Darah Bos

# Pastikan alamat scene peluru musuh ini BENER sesuai tempat lu nyimpen EnemyBullet.tscn
var enemy_bullet_scene = preload("res://Scenes/map/EnemyBullet.tscn") 

func _ready():
	add_to_group("enemy") # Tambahin baris ini
	pick_new_random_position()

func pick_new_random_position():
	# Nentuin koordinat ngacak di SETENGAH LAYAR KANAN
	var random_x = randf_range(700, 1100) 
	var random_y = randf_range(50, 600)
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
func _on_timer_timeout():
	# 1. Cari dimana Player berada (menggunakan grup yang kita buat di Tahap 1)
	var player = get_tree().get_first_node_in_group("player")
	
	# 2. Kalau Player ketemu, siapkan peluru!
	if player:
		# Bikin (Spawn) peluru merah
		var b = enemy_bullet_scene.instantiate()
		
		# Taruh pelurunya di arena (bukan di dalam perut bos)
		get_parent().add_child(b)
		b.global_position = self.global_position
		
		# 3. MENGINCAR PLAYER
		# Hitung garis lurus dari Bos ke arah posisi Player saat ini
		var aim_direction = (player.global_position - global_position).normalized()
		
		# Kasih tau pelurunya arah terbangnya ke mana
		b.direction = aim_direction
		
		# Putar gambar pelurunya biar moncongnya ngadep ke Player
		b.rotation = aim_direction.angle()
		
func take_damage(amount: float):
	hp -= amount
	print("Bos Kena Hit! Sisa HP Bos: ", hp)
	
	if hp <= 0:
		# Lapor ke arena kalau bos kalah (Misi Selesai)
		var arena = get_parent()
		if arena.has_method("enemy_defeated"):
			arena.enemy_defeated()
		queue_free() # Bos meledak
