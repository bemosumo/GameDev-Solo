extends CharacterBody2D

var speed: float = 400.0
var bullet_scene = preload("res://Scenes/map/Bullet.tscn")
var can_shoot: bool = false
@onready var health_bar = $HealthBar

func _ready():
	add_to_group("player")
	# Set bar sesuai data di GlobalData
	health_bar.max_value = GlobalData.max_hp
	health_bar.value = GlobalData.current_hp

func take_damage(amount: float):
	GlobalData.current_hp -= amount
	# Update visual bar
	health_bar.value = GlobalData.current_hp
	
	if GlobalData.current_hp <= 0:
		await get_tree().create_timer(1.0).timeout
		GlobalData.reset_data()
		GlobalData.last_player_pos = Vector2i(-1, -1)
		get_tree().change_scene_to_file("res://Scenes/map/TacticalMap.tscn")

func _physics_process(_delta):
	# Kapal tetep cuma bisa gerak kiri-kanan
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity = Vector2(direction * speed, 0)
	move_and_slide()

	global_position.x = clamp(global_position.x, 64, 1152 - 64)
	global_position.y = 580
	
	# (Baris Input.is_action_just_pressed("ui_accept") HAPUS DARI SINI)

# --- FUNGSI BARU UNTUK BACA KLIK MOUSE ---
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# TAMBAHAN: Cek dulu boleh nembak apa belum
		if can_shoot: 
			shoot()

func shoot():
	var b = bullet_scene.instantiate()
	get_parent().add_child(b)
	b.global_position = self.global_position
	
	# 1. Minta Godot cari tau dimana koordinat kursor mouse lu di layar
	var mouse_pos = get_global_mouse_position()
	
	# 2. Hitung garis lurus dari posisi kapal ke arah posisi kursor
	var aim_direction = (mouse_pos - global_position).normalized()
	
	# 3. Kasih tau peluru buat terbang ke arah kursor tersebut
	b.direction = aim_direction
	
	# 4. Putar gambar pelurunya biar moncongnya ngadep ke kursor
	b.rotation = aim_direction.angle()
	
#func take_damage(amount: float):
	#GlobalData.current_hp -= amount
	#print("ADUH! Sisa HP Player: ", GlobalData.current_hp)
	#
	#if GlobalData.current_hp <= 0:
		#print("KAPAL HANCUR! GAME OVER!")
		## 1. Kasih jeda dikit biar berasa matinya
		#await get_tree().create_timer(1.0).timeout
		#
		## 2. Reset semua data lu balik ke awal
		#GlobalData.reset_data()
		#GlobalData.last_player_pos = Vector2i(-1, -1) # Reset posisi spawn
		#
		## 3. Lempar balik ke Peta (Mulai dari nol)
		#get_tree().change_scene_to_file("res://Scenes/map/TacticalMap.tscn")
