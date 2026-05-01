extends Control

func _ready():
	# (Opsional) Kalo ada musik menu, bisa di-play di sini
	pass

func _on_start_button_pressed():
	# Pastiin path "res://..." ini sesuai sama letak TacticalMap lu!
	get_tree().change_scene_to_file("res://Scenes/map/TacticalMap.tscn")

func _on_quit_button_pressed():
	# Keluar dari game
	get_tree().quit()
