extends Node2D

# 1. Preload ke-8 pasukan lu
var carrier_scene = preload("res://Scenes/Enemies/EnemyCarrier.tscn")
var hovercraft_scene = preload("res://Scenes/Enemies/EnemyHovercraft.tscn")
var fregat_scene = preload("res://Scenes/Enemies/EnemyFregat.tscn")
var cruiser_scene = preload("res://Scenes/Enemies/EnemyCruiser.tscn")
var stealth_scene = preload("res://Scenes/Enemies/EnemyStealth.tscn")
var submarine_scene = preload("res://Scenes/Enemies/EnemySubmarine.tscn")
var buoy_scene = preload("res://Scenes/Enemies/ObstacleBuoy.tscn")
var mine_scene = preload("res://Scenes/Enemies/ObstacleMine.tscn")

var enemies_in_wave = 0

func _ready():
	setup_battle()

func setup_battle():
	var musuh = GlobalData.current_enemy_name
	
	if "Patrol" in musuh:
		spawn_unit(hovercraft_scene, Vector2(576, 150))
		spawn_unit(fregat_scene, Vector2(250, 100))
		spawn_unit(fregat_scene, Vector2(900, 100))
		enemies_in_wave = 3
		
	elif "Cruiser" in musuh:
		spawn_unit(cruiser_scene, Vector2(576, 100))
		spawn_unit(stealth_scene, Vector2(300, 200))
		spawn_unit(stealth_scene, Vector2(850, 200))
		enemies_in_wave = 3
		
	elif "Carrier" in musuh:
		spawn_unit(carrier_scene, Vector2(576, 80))
		spawn_unit(submarine_scene, Vector2(200, 300))
		spawn_unit(submarine_scene, Vector2(950, 300))
		enemies_in_wave = 3
		
	elif "Invasion" in musuh:
		spawn_unit(fregat_scene, Vector2(576, 150))
		# Rintangan gak perlu mati buat menang, tapi kita hitung sementara
		spawn_unit(mine_scene, Vector2(250, 250))
		spawn_unit(buoy_scene, Vector2(900, 250))
		enemies_in_wave = 3
	else:
		# Default kalau error/nama gak cocok
		spawn_unit(hovercraft_scene, Vector2(576, 150))
		enemies_in_wave = 1

func spawn_unit(scene_kapal, pos: Vector2):
	var enemy = scene_kapal.instantiate()
	add_child(enemy)
	
	# Spawn dari atas luar layar
	enemy.global_position = Vector2(pos.x, -200)
	
	# Sambungin sinyal mati biar gamenya tau kapan selesai
	enemy.defeated.connect(_on_enemy_defeated)
	
	# Animasi turun
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(enemy, "global_position", pos, 2.5)

func _on_enemy_defeated():
	enemies_in_wave -= 1
	if enemies_in_wave <= 0:
		finish_battle()

func finish_battle():
	print("Semua Musuh Rata! Balik ke Map.")
	GlobalData.defeated_enemies.append(GlobalData.current_enemy_name)
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://Scenes/map/TacticalMap.tscn")
