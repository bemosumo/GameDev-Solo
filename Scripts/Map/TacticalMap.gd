extends Node2D

@onready var tilemap = $Laut
@onready var layer_pulau = $Pulau
@onready var player = $PlayerCursor
@onready var ammo_label = $PlayerCursor/AmmoLabel # Ambil referensi ke Label Ammo

var is_moving = false
var current_map_pos = Vector2i()

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
		
		if mobs_defeated >= 4:
			boss_node.show() 
			boss_node.process_mode = Node.PROCESS_MODE_INHERIT
			
			# Otomatis cari tau posisi boss di grid buat dicat merah
			var boss_grid_pos = tilemap.local_to_map(tilemap.to_local(boss_node.global_position))
			merahin_area_boss(boss_grid_pos)
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
	calculate_reachable_cells()
	queue_redraw() # Panggil fungsi _draw() buat nge-highlight kotak

func scan_enemies():
	enemy_positions.clear()
	for child in get_children():
		# Cek apakah dia Mob atau Boss, dan pastikan dia GAK lagi sembunyi
		if child is Area2D and ("MobNode" in child.name or "BossNode" in child.name) and not child.is_queued_for_deletion():
			if child.visible: 
				var grid_pos = tilemap.local_to_map(tilemap.to_local(child.global_position))
				
				# LOGIKA BARU: Kalo dia Boss, daftarin 4 kotak sekaligus!
				if "BossNode" in child.name:
					enemy_positions[grid_pos] = child                           # Kiri Atas
					enemy_positions[grid_pos + Vector2i(1, 0)] = child          # Kanan Atas
					enemy_positions[grid_pos + Vector2i(0, 1)] = child          # Kiri Bawah
					enemy_positions[grid_pos + Vector2i(1, 1)] = child          # Kanan Bawah
				else:
					# Kalo Kroco biasa, cukup 1 kotak aja
					enemy_positions[grid_pos] = child

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
	
	for cell in reachable_cells.keys():
		if cell == current_map_pos: continue
		
		var center_pos = tilemap.map_to_local(cell)
		var rect = Rect2(center_pos - Vector2(t_size.x/2.0, t_size.y/2.0), t_size)
		
		if enemy_positions.has(cell):
			draw_rect(rect, Color(1.0, 0.2, 0.2, 0.4))
		else:
			draw_rect(rect, Color(0.2, 0.6, 1.0, 0.4))

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
		# ... (kode tween gerak tetap sama)
		var target_pixel_pos = tilemap.to_global(tilemap.map_to_local(next_tile))
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(player, "global_position", target_pixel_pos, 0.25)
		await tween.finished
		
		current_map_pos = next_tile
		
	if enemy_positions.has(current_map_pos):
				# --- SIMPAN POSISI SEBELUM PINDAH SCENE ---
				GlobalData.last_player_pos = current_map_pos
				
				var enemy_node = enemy_positions[current_map_pos]
				GlobalData.current_enemy_name = enemy_node.name
				
				# (BARIS GlobalData.use_ammo(1) DAN update_ammo_ui() DIHAPUS DARI SINI)
				
				enemy_node.queue_free()
				
				await get_tree().create_timer(0.5).timeout
				get_tree().change_scene_to_file("res://Scenes/map/BattlePhase.tscn")
				return
				
	is_moving = false
	# --- UPDATE JUGA POSISI TERAKHIR SETIAP SELESAI GERAK BIASA ---
	GlobalData.last_player_pos = current_map_pos
	update_tactical_data()

# ==========================================
# FUNGSI BUAT NGECAT 4 KOTAK BOSS
# ==========================================
func merahin_area_boss(kiri_atas: Vector2i):
	# Sesuaikan 3 angka ini dengan TileSet lu!
	var layer_map = 0 # Biasanya 0 atau 1
	var source_id = 0 # ID atlas (coba cek di tab TileSet)
	var atlas_merah = Vector2i(0, 0) # Koordinat kotak merah di DALAM gambar tileset
	
	# Bikin daftar 4 kotak (Formasi 2x2)
	var area_boss = [
		kiri_atas,
		kiri_atas + Vector2i(1, 0),
		kiri_atas + Vector2i(0, 1),
		kiri_atas + Vector2i(1, 1)
	]
	
	# Warnain keempat kotaknya ke TileMap
	for cell in area_boss:
		tilemap.set_cell(layer_map, cell, source_id, atlas_merah)
