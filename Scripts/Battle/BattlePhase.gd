extends Node2D

var is_battle_over = false

# Fungsi ini bakal dipanggil sama peluru kalau musuh mati
func enemy_defeated():
	if is_battle_over: return 
	is_battle_over = true
	
	# MASUKKAN NAMA MUSUH KE DAFTAR KEMATIAN
	if GlobalData.current_enemy_name != "":
		GlobalData.defeated_enemies.append(GlobalData.current_enemy_name)
	
	print("Musuh ", GlobalData.current_enemy_name, " dikalahkan!")
	
	await get_tree().create_timer(1.0).timeout 
	get_tree().change_scene_to_file("res://Scenes/map/TacticalMap.tscn")
