extends Node2D

@onready var tilemap = $Laut
@onready var layer_pulau = $Pulau
@onready var player = $PlayerCursor
@onready var ammo_label = $PlayerCursor/AmmoLabel # Ambil referensi ke Label Ammo

var is_moving = false
var current_map_pos = Vector2i()
var item_positions = {}
# Dictionary buat nyimpen data taktis
var reachable_cells = {}
var enemy_positions = {}

func _ready():
	# 1. Hapus musuh yang sudah mati (Persistence)
	for enemy_name in GlobalData.defeated_enemies:
		var node_musuh = get_node_or_null(enemy_name)
		if node_musuh:
			node_musuh.queue_free()

# --- 2. LOGIKA MUNCULIN BOSS ---
	var boss_node = get_node_or_null("BossNode")
	if boss_node:
		var mobs_defeated = 0
		for enemy_name in GlobalData.defeated_enemies:
			if "MobNode" in enemy_name:
				mobs_defeated += 1
		
		if mobs_defeated >= 0:
			boss_node.show() 
			boss_node.process_mode = Node.PROCESS_MODE_INHERIT
			
			# Langsung panggil fungsinya
			merahin_area_boss()
		else:
			boss_node.hide() 
			boss_node.process_mode = Node.PROCESS_MODE_DISABLED
	# --------------------------------
	# LOGIKA POSISI BARU:
	if GlobalData.last_player_pos != Vector2i(-1, -1):
		current_map_pos = GlobalData.last_player_pos
	else:
		var player_local_pos = tilemap.to_local(player.global_position)
		current_map_pos = tilemap.local_to_map(player_local_pos)
	
	player.global_position = tilemap.to_global(tilemap.map_to_local(current_map_pos))
	
	update_tactical_data()
	update_ammo_ui()

@onready var health_bar = $PlayerCursor/HealthBar

func update_ammo_ui():
	if ammo_label:
		ammo_label.text = str(GlobalData.current_ammo) + "/" + str(GlobalData.max_ammo)
	# Update HP Bar di Map juga
	if health_bar:
		health_bar.max_value = GlobalData.max_hp
		health_bar.value = GlobalData.current_hp

func update_tactical_data():
	scan_enemies()
	scan_items() # TAMBAHIN BARIS INI
	calculate_reachable_cells()
	queue_redraw()

func scan_enemies():
	enemy_positions.clear()
	for child in get_children():
		# Cek apakah dia Mob atau Boss, dan pastikan dia GAK lagi sembunyi
		if child is Area2D and ("MobNode" in child.name or "BossNode" in child.name) and not child.is_queued_for_deletion():
			if child.visible: 
				# KALO BOSS, KUNCI DI 6 KOORDINAT INI!
				if "BossNode" in child.name:	
					var area_boss = [
						Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1),
						Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2)
					]
					for cell in area_boss:
						enemy_positions[cell] = child
				# KALO KROCO, BACA POSISI OTOMATIS
				else:
					var grid_pos = tilemap.local_to_map(tilemap.to_local(child.global_position))
					enemy_positions[grid_pos] = child

func scan_items():
	item_positions.clear()
	for child in get_children():
		# Deteksi kalau namanya mengandung "ItemAmmo" atau "ItemMedkit"
		if child is Area2D and ("ItemAmmo" in child.name or "ItemMedkit" in child.name) and not child.is_queued_for_deletion():
			var grid_pos = tilemap.local_to_map(tilemap.to_local(child.global_position))
			item_positions[grid_pos] = child
			
func calculate_reachable_cells():
	reachable_cells.clear()
	var queue = [{"pos": current_map_pos, "path": [current_map_pos]}]
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var pos = current["pos"]
		var path = current["path"]
		
		if not reachable_cells.has(pos) or path.size() < reachable_cells[pos].size():
			reachable_cells[pos] = path
			
			if path.size() - 1 < 3:
				for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
					var next_pos = pos + dir
					if next_pos in path: continue
					
					var tile_data = tilemap.get_cell_tile_data(next_pos)
					if tile_data and tile_data.get_custom_data("walkable"):
						var new_path = path.duplicate()
						new_path.append(next_pos)
						
						if enemy_positions.has(next_pos):
							if not reachable_cells.has(next_pos) or new_path.size() < reachable_cells[next_pos].size():
								reachable_cells[next_pos] = new_path
						else:
							queue.append({"pos": next_pos, "path": new_path})

func _draw():
	if is_moving: return
	
	var t_size = tilemap.tile_set.tile_size
	
	# =======================================================
	# TAHAP 1: Area Jangkauan Player (Biru & Merah Standar)
	# =======================================================
	for cell in reachable_cells.keys():
		if cell == current_map_pos: continue
		
		var center_pos = tilemap.map_to_local(cell)
		var rect = Rect2(center_pos - Vector2(t_size.x/2.0, t_size.y/2.0), t_size)
		
		if enemy_positions.has(cell):
			draw_rect(rect, Color(1.0, 0.2, 0.2, 0.4)) # Merah kalau ada musuh
		else:
			draw_rect(rect, Color(0.2, 0.6, 1.0, 0.4)) # Biru kalau kosong
			
	# =======================================================
	# TAHAP 2: Pengecualian Khusus Boss (Aura Intimidasi)
	# =======================================================
	for cell in enemy_positions.keys():
		var node_musuh = enemy_positions[cell]
		
		# Cek apakah node ini namanya mengandung "BossNode"
		if "BossNode" in node_musuh.name:
			# Kalo kotaknya Boss ini DI LUAR jangkauan (belum kegambar di Tahap 1)
			if not reachable_cells.has(cell):
				var center_pos = tilemap.map_to_local(cell)
				var rect = Rect2(center_pos - Vector2(t_size.x/2.0, t_size.y/2.0), t_size)
				
				# Paksa gambar warna merah!
				draw_rect(rect, Color(1.0, 0.2, 0.2, 0.4))

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_moving: return

		var mouse_pos = tilemap.get_local_mouse_position()
		var target_map_pos = tilemap.local_to_map(mouse_pos)
		
		if reachable_cells.has(target_map_pos) and target_map_pos != current_map_pos:
			var path_to_take = reachable_cells[target_map_pos]
			path_to_take.pop_front()
			move_player_along_path(path_to_take)
		else:
			print("Gak bisa ke situ komandan!")

func move_player_along_path(path):
	is_moving = true
	queue_redraw()
	
	for next_tile in path:
		var target_pixel_pos = tilemap.to_global(tilemap.map_to_local(next_tile))
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(player, "global_position", target_pixel_pos, 0.25)
		await tween.finished
		
		current_map_pos = next_tile
		
	if item_positions.has(current_map_pos):
			var item_node = item_positions[current_map_pos]
			
			# Kalau nginjek ItemAmmo (+3 Ammo)
			if "ItemAmmo" in item_node.name:
				GlobalData.current_ammo += 3
				if GlobalData.current_ammo > GlobalData.max_ammo:
					GlobalData.current_ammo = GlobalData.max_ammo
				print("AMMO DIAMBIL! Ammo sekarang: ", GlobalData.current_ammo)
				
			# Kalau nginjek ItemMedkit (+50% HP)
			elif "ItemMedkit" in item_node.name:
				var heal_amount = GlobalData.max_hp * 0.5
				GlobalData.current_hp += heal_amount
				if GlobalData.current_hp > GlobalData.max_hp:
					GlobalData.current_hp = GlobalData.max_hp
				print("MEDKIT DIAMBIL! HP sekarang: ", GlobalData.current_hp)
					
			# Hapus itemnya dari map & update UI
			item_node.queue_free()
			item_positions.erase(current_map_pos)
			update_ammo_ui() # Fungsi lu yang kemaren buat update Bar HP & Teks Ammo
		# =======================================================
		
	# (LOGIKA NABRAK MUSUH TETEP SAMA KAYAK SEBELUMNYA DI SINI)
	if enemy_positions.has(current_map_pos):
		GlobalData.last_player_pos = current_map_pos
		var enemy_node = enemy_positions[current_map_pos]
		GlobalData.current_enemy_name = enemy_node.name
		enemy_node.queue_free()
		
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://Scenes/map/BattlePhase.tscn")
		return
				
	is_moving = false
	GlobalData.last_player_pos = current_map_pos
	update_tactical_data()

# ==========================================
# FUNGSI BUAT NGECAT 6 KOTAK BOSS
# ==========================================
func merahin_area_boss():
	var source_id = 0 # Pastiin ID atlas merah lu bener
	var atlas_merah = Vector2i(0, 0) # Pastiin koordinat kotak merah di TileSet lu bener
	
	# KOORDINAT PRESISI DARI KOMANDAN
	var area_boss = [
		Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1),
		Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2)
	]
	
	# Warnain keenam kotaknya ke TileMapLayer
	for cell in area_boss:
		tilemap.set_cell(cell, source_id, atlas_merah)
