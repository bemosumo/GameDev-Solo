extends CanvasLayer

@onready var popup_panel = $PopupPanel
@onready var star1 = $PopupPanel/VBoxContainer/HBoxContainer/Star1
@onready var star2 = $PopupPanel/VBoxContainer/HBoxContainer/Star2
@onready var star3 = $PopupPanel/VBoxContainer/HBoxContainer/Star3

func _ready():
	# Sembunyiin popup pas awal mulai
	popup_panel.hide()

# --- TOMBOL PAUSE DI KLIK ---
func _on_tombol_pause_pressed():
	# 1. Hentikan waktu game!
	get_tree().paused = true
	
	# 2. Munculin Popup
	popup_panel.show()
	
	# 3. Cek dapet bintang berapa
	update_bintang()

func update_bintang():
	# BINTANG 1: Clear Stage
	if GlobalData.star_stage_cleared:
		star1.modulate = Color(1, 1, 1) # Nyala (Terang)
	else:
		star1.modulate = Color(0.2, 0.2, 0.2) # Gelap (Belom dapet)
		
	# BINTANG 2: Kalahkan Boss
	if GlobalData.star_boss_defeated:
		star2.modulate = Color(1, 1, 1)
	else:
		star2.modulate = Color(0.2, 0.2, 0.2)
		
	# BINTANG 3: Kalahkan Semua Musuh
	if GlobalData.star_all_enemies:
		star3.modulate = Color(1, 1, 1)
	else:
		star3.modulate = Color(0.2, 0.2, 0.2)

# --- TOMBOL RESUME DI KLIK ---
func _on_btn_resume_pressed():
	# Sembunyiin popup dan jalanin waktu game lagi
	popup_panel.hide()
	get_tree().paused = false

# --- TOMBOL QUIT DI KLIK ---
func _on_btn_quit_pressed():
	# PENTING: Unpause dulu sebelum pindah scene!
	get_tree().paused = false 
	get_tree().change_scene_to_file("res://Scenes/map/TacticalMap.tscn") # Balik ke menu awal
