extends Node2D

var carrier_scene = preload("res://Scenes/Enemies/EnemyCarrier.tscn")
var hovercraft_scene = preload("res://Scenes/Enemies/EnemyHovercraft.tscn")
var fregat_scene = preload("res://Scenes/Enemies/EnemyFregat.tscn")
var cruiser_scene = preload("res://Scenes/Enemies/EnemyCruiser.tscn")
var stealth_scene = preload("res://Scenes/Enemies/EnemyStealth.tscn")
var sub_scene = preload("res://Scenes/Enemies/EnemySubmarine.tscn")
var buoy_scene = preload("res://Scenes/Enemies/ObstacleBuoy.tscn")
var mine_scene = preload("res://Scenes/Enemies/ObstacleMine.tscn")
var boss_scene = preload("res://Scenes/Enemies/Boss.tscn")

var active_enemies = [] # DAFTAR ABSEN: Menggantikan enemies_in_wave
var current_wave = 1
var is_battle_finished: bool = false

func _ready():
	setup_battle()
	
	# WAKTU TUNGGU DISAMAIN SAMA DURASI ANIMASI (6 Detik)
	await get_tree().create_timer(4.0).timeout
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.can_shoot = true

func setup_battle():
	var musuh = GlobalData.current_enemy_name
	current_wave = 1 # Pastikan selalu mulai dari wave 1
	
	if "Boss" in musuh:
		# 1 Carrier di atas (Tengah)
		spawn_unit(carrier_scene, Vector2(576, 150), "KIRI") 
		
		# 2 Hovercraft di bawah (Kiri dan Kanan)
		spawn_unit(hovercraft_scene, Vector2(250, 300), "KIRI")  
		spawn_unit(hovercraft_scene, Vector2(900, 300), "KIRI")
				
	elif "Patrol" in musuh:
		spawn_unit(hovercraft_scene, Vector2(576, 180), "KIRI") 
		spawn_unit(fregat_scene, Vector2(200, 300), "KIRI")  
		spawn_unit(fregat_scene, Vector2(950, 300), "KIRI")
		
	elif "Cruiser" in musuh:
		spawn_unit(cruiser_scene, Vector2(576, 160), "KIRI")
		spawn_unit(stealth_scene, Vector2(250, 280), "KIRI")
		spawn_unit(stealth_scene, Vector2(900, 280), "KIRI")
		
	elif "Carrier" in musuh:
		spawn_unit(carrier_scene, Vector2(576, 150), "KIRI")
		spawn_unit(sub_scene, Vector2(200, 310), "KIRI")
		spawn_unit(sub_scene, Vector2(950, 310), "KIRI")
		
	elif "Invasion" in musuh:
		spawn_unit(fregat_scene, Vector2(576, 180), "KIRI")
		spawn_unit(fregat_scene, Vector2(250, 300), "KIRI")
		spawn_unit(fregat_scene, Vector2(900, 300), "KIRI")
		
	else:
		spawn_unit(hovercraft_scene, Vector2(576, 180), "KIRI")

	# PANGGIL DI SINI BIAR SEMUA NODE KEBAGIAN HUJAN RINTANGAN
	mulai_hujan_rintangan()


func spawn_unit(scene_musuh, pos_tujuan: Vector2, _arah_datang: String):
	if scene_musuh == null: return
	var enemy = scene_musuh.instantiate()
	add_child(enemy)
	
	# POSISI AWAL DIPAKSA DARI KIRI JAUH (-300) BIAR GAK KELIATAN TIBA-TIBA MUNCUL
	var pos_awal_x = -300 
	enemy.global_position = Vector2(pos_awal_x, pos_tujuan.y)
	
	# MASUKIN KE DAFTAR ABSEN DAN SAMBUNGIN SINYAL KEMATIAN
	active_enemies.append(enemy)
	enemy.defeated.connect(_on_unit_destroyed.bind(enemy))
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	
	# DURASI ANIMASI DIPERLAMBAT JADI 6.0 DETIK
	tween.tween_property(enemy, "global_position", pos_tujuan, 6.0)
	
	tween.tween_callback(func(): 
		if is_instance_valid(enemy):
			if "can_shoot" in enemy: 
				enemy.can_shoot = true
	)

func _on_unit_destroyed(unit):
	# ANTI BUG OVERKILL: Kalo musuh udah kecoret dari daftar, cuekin!
	if not active_enemies.has(unit):
		return
		
	# CORET DARI DAFTAR ABSEN
	active_enemies.erase(unit)
	
	var musuh = GlobalData.current_enemy_name
	
	# CEK: Kalau lagi di node Boss dan Wave 1 udah bener-bener bersih
	if "Boss" in musuh and current_wave == 1:
		if active_enemies.size() == 0:
			current_wave = 2
			obstacle_timer.stop()
			panggil_boss() # Turunin Boss-nya!
	else:
		# Kalau musuh biasa, atau Boss (Wave 2) udah mati, baru menang
		if active_enemies.size() == 0:
			finish_battle()

func finish_battle():
	# CEK GEMBOK: Kalau udah pernah dipanggil, langsung stop biar gak dobel!
	if is_battle_finished:
		return 
		
	is_battle_finished = true # Kunci gemboknya sekarang
	
	if GlobalData.has_method("use_ammo"):
		GlobalData.use_ammo(1) 
	
	if GlobalData.current_enemy_name != "":
		GlobalData.defeated_enemies.append(GlobalData.current_enemy_name)
		
	await get_tree().create_timer(1.0).timeout
	
	# Pengecekan ekstra: pastiin get_tree() beneran masih ada sebelum pindah
	if get_tree():
		get_tree().change_scene_to_file("res://Scenes/map/TacticalMap.tscn")

# ==========================================
# SISTEM HUJAN RINTANGAN (OBSTACLE)
# ==========================================
var obstacle_timer: Timer

func mulai_hujan_rintangan():
	# Tunggu 6 detik biar kapalnya selesai parkir dulu
	await get_tree().create_timer(6.0).timeout
	
	obstacle_timer = Timer.new()
	obstacle_timer.wait_time = 1.5 
	obstacle_timer.autostart = true
	obstacle_timer.timeout.connect(_spawn_random_obstacle)
	add_child(obstacle_timer)

func _spawn_random_obstacle():
	# Cari semua kapal musuh yang MASIH HIDUP di medan tempur
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	# Kalau musuhnya udah hancur semua, berhenti nebar ranjau
	if enemies.size() == 0:
		return
		
	# Pilih SATU kapal musuh secara acak buat jadi penebar ranjau detik ini
	var kapal_penebar = enemies[randi() % enemies.size()]
	
	# Pastikan kapalnya beneran masih ada (belum meledak pas mau nebar)
	if is_instance_valid(kapal_penebar):
		var is_mine = randi() % 2 == 0 
		var obs = mine_scene.instantiate() if is_mine else buoy_scene.instantiate()
		add_child(obs)
		
		# Keluarin rintangan tepat di koordinat kapal yang kepilih!
		obs.global_position = kapal_penebar.global_position

func panggil_boss():
	if boss_scene == null: return
	
	var boss = boss_scene.instantiate()
	add_child(boss)
	
	# MUNCUL DARI ATAS LAYAR (Sumbu Y Minus)
	var pos_awal = Vector2(576, -500) # Dibikin lebih tinggi karena badannya gede
	var pos_tujuan = Vector2(576, 50) # Berhenti di posisi kapal induk
	
	boss.global_position = pos_awal
	
	# DAFTARIN BOSS KE ARRAY ABSEN
	active_enemies.append(boss)
	boss.defeated.connect(_on_unit_destroyed.bind(boss))
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# Turun dengan gaya (6 detik)
	tween.tween_property(boss, "global_position", pos_tujuan, 6.0)
	
	tween.tween_callback(func(): 
		if is_instance_valid(boss):
			if "can_shoot" in boss: 
				boss.can_shoot = true
	);
