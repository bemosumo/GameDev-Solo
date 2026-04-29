# Ini contoh buat Enemy_Carrier.gd
extends EnemyBase

func _ready():
	hp = 10 # Darah Carrier lebih tebal
	super._ready() # Wajib panggil ini biar timer-nya nyala

func _on_area_entered(area: Area2D) -> void:
	pass # Replace with function body.
