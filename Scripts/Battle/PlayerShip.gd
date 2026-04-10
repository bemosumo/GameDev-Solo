extends CharacterBody2D

var speed: float = 400.0
var bullet_scene = preload("res://Scenes/map/Bullet.tscn") 

func _ready():
	# PENTING: Masukin kapal ini ke grup "player" biar bisa dilacak musuh
	add_to_group("player")

func _physics_process(_delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	move_and_slide()

	# BATASIN AREA GERAK (Asumsi lebar layar 1152 dan tinggi 648)
	# x maksimal 570 (setengah layar), y maksimal 600
	global_position.x = clamp(global_position.x, 0, 570)
	global_position.y = clamp(global_position.y, 0, 648)

	if Input.is_action_just_pressed("ui_accept"): 
		shoot()

func shoot():
	var b = bullet_scene.instantiate()
	get_parent().add_child(b) 
	b.position = self.position
	
func take_damage(amount: float):
	GlobalData.current_hp -= amount
	print("ADUH! Sisa HP Player: ", GlobalData.current_hp)
	
	if GlobalData.current_hp <= 0:
		print("KAPAL HANCUR! GAME OVER!")
		# 1. Kasih jeda dikit biar berasa matinya
		await get_tree().create_timer(1.0).timeout 
		
		# 2. Reset semua data lu balik ke awal
		GlobalData.reset_data() 
		GlobalData.last_player_pos = Vector2i(-1, -1) # Reset posisi spawn
		
		# 3. Lempar balik ke Peta (Mulai dari nol)
		get_tree().change_scene_to_file("res://Scenes/map/TacticalMap.tscn")
