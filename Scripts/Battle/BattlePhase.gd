extends Node2D

var carrier_scene = preload("res://Scenes/Enemies/EnemyCarrier.tscn")
var hovercraft_scene = preload("res://Scenes/Enemies/EnemyHovercraft.tscn")
var fregat_scene = preload("res://Scenes/Enemies/EnemyFregat.tscn")
var cruiser_scene = preload("res://Scenes/Enemies/EnemyCruiser.tscn")
var stealth_scene = preload("res://Scenes/Enemies/EnemyStealth.tscn")
var sub_scene = preload("res://Scenes/Enemies/EnemySubmarine.tscn")
var buoy_scene = preload("res://Scenes/Enemies/ObstacleBuoy.tscn")
var mine_scene = preload("res://Scenes/Enemies/ObstacleMine.tscn")

var enemies_in_wave = 0

func _ready():
	setup_battle()
	
	# WAKTU TUNGGU DISAMAIN SAMA DURASI ANIMASI (6 Detik)
	await get_tree().create_timer(6.0).timeout
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.can_shoot = true

func setup_battle():
	var musuh = GlobalData.current_enemy_name
	
	if "Patrol" in musuh:
		spawn_unit(hovercraft_scene, Vector2(576, 180), "KIRI") 
		spawn_unit(fregat_scene, Vector2(200, 300), "KIRI")  
		spawn_unit(fregat_scene, Vector2(950, 300), "KIRI")
		enemies_in_wave = 3
	elif "Cruiser" in musuh:
		spawn_unit(cruiser_scene, Vector2(576, 160), "KIRI")
		spawn_unit(stealth_scene, Vector2(250, 280), "KIRI")
		spawn_unit(stealth_scene, Vector2(900, 280), "KIRI")
		enemies_in_wave = 3
	elif "Carrier" in musuh:
		spawn_unit(carrier_scene, Vector2(576, 150), "KIRI")
		spawn_unit(sub_scene, Vector2(200, 310), "KIRI")
		spawn_unit(sub_scene, Vector2(950, 310), "KIRI")
		enemies_in_wave = 3
	elif "Invasion" in musuh:
		spawn_unit(fregat_scene, Vector2(576, 180), "KIRI")
		spawn_unit(fregat_scene, Vector2(250, 300), "KIRI")
		spawn_unit(fregat_scene, Vector2(900, 300), "KIRI")
		enemies_in_wave = 3
	else:
		spawn_unit(hovercraft_scene, Vector2(576, 180), "KIRI")
		enemies_in_wave = 1

	# PANGGIL DI SINI BIAR SEMUA NODE KEBAGIAN HUJAN RINTANGAN
	mulai_hujan_rintangan()


func spawn_unit(scene_musuh, pos_tujuan: Vector2, _arah_datang: String):
	if scene_musuh == null: return
	var enemy = scene_musuh.instantiate()
	add_child(enemy)
	
	# POSISI AWAL DIPAKSA DARI KIRI JAUH (-300) BIAR GAK KELIATAN TIBA-TIBA MUNCUL
	var pos_awal_x = -300 
	enemy.global_position = Vector2(pos_awal_x, pos_tujuan.y)
	
	enemy.defeated.connect(_on_enemy_defeated)
	
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

func _on_enemy_defeated():
	enemies_in_wave -= 1
	if enemies_in_wave <= 0:
		finish_battle()

func finish_battle():
	if GlobalData.has_method("use_ammo"):
		GlobalData.use_ammo(1) 
	
	if GlobalData.current_enemy_name != "":
		GlobalData.defeated_enemies.append(GlobalData.current_enemy_name)
		
	await get_tree().create_timer(1.0).timeout
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
