extends Node

# --- DATA AMUNISI (D90) ---
var max_ammo: int = 5
var current_ammo: int = 5

# --- DATA STAT KAPAL ---
var max_hp: int = 300
var current_hp: int = 300
var base_damage: float = 10.0

# --- DATA PERSISTENCE (PENTING BUAT MAP) ---
var defeated_enemies: Array = []
var current_enemy_name: String = ""
var last_player_pos: Vector2i = Vector2i(-1, -1)

func use_ammo(amount: int = 1):
	current_ammo -= amount
	if current_ammo < 0:
		current_ammo = 0
	print("Sisa Ammo sekarang: ", current_ammo)

func get_final_damage() -> float:
	if current_ammo > 0:
		return base_damage * 1.2 
	else:
		return base_damage * 0.8

func reset_data():
	current_ammo = max_ammo
	current_hp = max_hp
	defeated_enemies.clear() 
	current_enemy_name = ""
