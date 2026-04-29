extends Node2D

var stationary_scene = preload("res://Scenes/map/StationaryEnemy.tscn")
# Pastikan path ini sesuai dengan nama dan tempat lu nyimpen scene Boss!
var boss_scene = preload("res://Scenes/map/Boss.tscn") 

var current_wave = 1
var enemies_in_wave = 0
var is_boss_battle = false 

func _ready():
	# Cek apakah musuh yang ditabrak di map adalah Boss
	if "BossNode" in GlobalData.current_enemy_name:
		is_boss_battle = true
	else:
		is_boss_battle = false
		
	spawn_wave_1()

func spawn_wave_1():
	print("Wave 1: 3 Stationary Enemies")
	# Taruh berjejer dari kiri, tengah, kanan di layar atas
	spawn_stationary(Vector2(250, 150))
	spawn_stationary(Vector2(576, 100)) # Tengah
	spawn_stationary(Vector2(900, 150))
	enemies_in_wave = 3

func spawn_wave_2():
	print("Wave 2: 2 Stationary Enemies")
	spawn_stationary(Vector2(400, 150))
	spawn_stationary(Vector2(750, 150))
	enemies_in_wave = 2

func spawn_wave_3():
	if is_boss_battle:
		print("Final Wave: Boss + 2 Stationary")
		
		var boss = boss_scene.instantiate()
		add_child(boss)
		
		# Taruh Boss di LUAR LAYAR ATAS (Y = -200), tengah-tengah (X = 576)
		boss.global_position = Vector2(576, -200) 
		boss.defeated.connect(_on_enemy_defeated)
		boss.set_physics_process(false) 
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUART)
		tween.set_ease(Tween.EASE_OUT)
		# Tarik Boss ke tengah atas (Y = 150)
		tween.tween_property(boss, "global_position", Vector2(576, 150), 2.5) 
		tween.tween_callback(func(): boss.set_physics_process(true)) 
		
		# Spawn Kroco Pendamping di kiri-kanan Boss
		spawn_stationary(Vector2(200, 100))
		spawn_stationary(Vector2(950, 100))
		enemies_in_wave = 3 
	else:
		print("Final Wave: 3 Stationary Enemies (Kroco Doang)")
		spawn_stationary(Vector2(250, 150))
		spawn_stationary(Vector2(576, 100))
		spawn_stationary(Vector2(900, 150))
		enemies_in_wave = 3

func spawn_stationary(pos: Vector2):
	var enemy = stationary_scene.instantiate()
	add_child(enemy)
	
	# Taruh kroco di LUAR LAYAR ATAS (X sesuai target, Y = -200)
	enemy.global_position = Vector2(pos.x, -200)
	enemy.defeated.connect(_on_enemy_defeated)
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(enemy, "global_position", pos, 2.5)

# --- FUNGSI LOGIKA GELOMBANG ---
func _on_enemy_defeated():
	enemies_in_wave -= 1
	if enemies_in_wave <= 0:
		next_wave()

func next_wave():
	current_wave += 1
	await get_tree().create_timer(1.5).timeout # Jeda 1.5 detik biar player nafas dulu
	
	if current_wave == 2:
		spawn_wave_2()
	elif current_wave == 3:
		spawn_wave_3()
	else:
		finish_battle()

func finish_battle():
	if GlobalData.current_enemy_name != "":
		GlobalData.defeated_enemies.append(GlobalData.current_enemy_name)
		
	# --- POTONG PELURU DI SINI SETELAH MENANG ---
	GlobalData.use_ammo(1) 
	
	print("Semua musuh habis! Kembali ke Map.")
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://Scenes/map/TacticalMap.tscn")
