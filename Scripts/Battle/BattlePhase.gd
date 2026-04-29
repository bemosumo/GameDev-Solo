extends Node2D

# Pastikan path ini sesuai dengan nama folder tempat lu nyimpen 8 scene musuhnya!
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

func setup_battle():
	var musuh = GlobalData.current_enemy_name
	
	# --- FORMASI PATROL FLEET ---
	if "Patrol" in musuh:
		spawn_unit(hovercraft_scene, Vector2(576, 120), "KIRI") 
		spawn_unit(fregat_scene, Vector2(300, 80), "KANAN")  
		spawn_unit(fregat_scene, Vector2(850, 80), "KIRI")
		enemies_in_wave = 3
		
	# --- FORMASI HEAVY STRIKE ---
	elif "Cruiser" in musuh:
		spawn_unit(cruiser_scene, Vector2(576, 100), "KANAN")
		spawn_unit(stealth_scene, Vector2(300, 180), "KIRI")
		spawn_unit(stealth_scene, Vector2(850, 180), "KANAN")
		enemies_in_wave = 3
		
	# --- FORMASI DEEP SEA CARRIER ---
	elif "Carrier" in musuh:
		spawn_unit(carrier_scene, Vector2(576, 80), "KIRI")
		spawn_unit(sub_scene, Vector2(200, 200), "KANAN")
		spawn_unit(sub_scene, Vector2(950, 200), "KIRI")
		enemies_in_wave = 3
		
	# --- FORMASI INVASION FORCE (Pakai Rintangan) ---
	elif "Invasion" in musuh:
		spawn_unit(fregat_scene, Vector2(576, 150), "KANAN")
		spawn_unit(mine_scene, Vector2(300, 250), "KIRI")
		spawn_unit(buoy_scene, Vector2(850, 250), "KANAN")
		enemies_in_wave = 3
		
	# --- DEFAULT JAGA-JAGA ---
	else:
		spawn_unit(hovercraft_scene, Vector2(576, 150), "KIRI")
		enemies_in_wave = 1


# Fungsi buat nurunin musuh dari pinggir layar trus berenti di posisi
func spawn_unit(scene_musuh, pos_tujuan: Vector2, arah_datang: String):
	if scene_musuh == null:
		print("Error: Scene musuh belum di-preload, path salah!")
		return
		
	var enemy = scene_musuh.instantiate()
	add_child(enemy)
	
	# Tentukan posisi awal di luar layar (Kiri = -200, Kanan = 1350)
	var pos_awal_x = -200 if arah_datang == "KIRI" else 1350
	enemy.global_position = Vector2(pos_awal_x, pos_tujuan.y)
	
	# Sambungin sinyal mati biar gamenya tau kapan menang
	enemy.defeated.connect(_on_enemy_defeated)
	
	# Bikin animasi jalan biar mulus
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(enemy, "global_position", pos_tujuan, 2.0)
	
	# Pas udah sampe posisi, kasih aba-aba boleh nembak
	tween.tween_callback(func(): 
		if "can_shoot" in enemy:
			enemy.can_shoot = true
	)

func _on_enemy_defeated():
	enemies_in_wave -= 1
	if enemies_in_wave <= 0:
		finish_battle()

func finish_battle():
	print("Semua Musuh Hancur! Balik ke Map.")
	
	# Kurangin Ammo sesuai mekanik lu
	if GlobalData.has_method("use_ammo"):
		GlobalData.use_ammo(1) 
	
	# Catat musuh yang udah dikalahin biar pas balik ke map node-nya ilang
	if GlobalData.current_enemy_name != "":
		GlobalData.defeated_enemies.append(GlobalData.current_enemy_name)
		
	# Jeda dikit sebelum layar pindah
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://Scenes/map/TacticalMap.tscn")
