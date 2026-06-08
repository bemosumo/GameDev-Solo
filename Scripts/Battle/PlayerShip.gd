extends CharacterBody2D

var speed: float = 400.0
var bullet_scene = preload("res://Scenes/map/Bullet.tscn")
var can_shoot: bool = false

@onready var health_bar = $HealthBar
@onready var skill_bar = $SkillBar # Pastiin nama nodenya sama
@onready var shield_sprite = $ShieldSprite
@onready var shield_bar = get_node_or_null("../ShieldUI/ShieldCooldownBar")
@onready var shield_button = get_node_or_null("../ShieldUI/ShieldButton")
@export var laser_scene: PackedScene # Slot buat PlayerLaser.tscn

var charge_time: float = 8.0
var current_charge: float = 0.0
var is_skill_ready: bool = false
@export var shield_cooldown_time: float = 10.0
@export var shield_duration: float = 5.0
@export var shield_fade_time: float = 0.6
var current_shield_charge: float = 0.0
var is_shield_ready: bool = false
var is_shield_active: bool = false
var shield_tween: Tween
var shield_default_modulate: Color

func _ready():
	add_to_group("player")
	health_bar.max_value = GlobalData.max_hp
	health_bar.value = GlobalData.current_hp
	if skill_bar:
			skill_bar.max_value = charge_time
			skill_bar.value = 0.0 # Awalnya kosong
	if shield_bar:
		shield_bar.max_value = shield_cooldown_time
		shield_bar.value = 0.0
	if shield_button:
		shield_button.disabled = true
	if shield_sprite:
		shield_default_modulate = shield_sprite.modulate
		reset_shield_visual()
			
func take_damage(amount: float):
	if is_shield_active:
		return

	GlobalData.current_hp -= amount
	health_bar.value = GlobalData.current_hp
	
	if GlobalData.current_hp <= 0:
		await get_tree().create_timer(1.0).timeout
		GlobalData.reset_data()
		GlobalData.last_player_pos = Vector2i(-1, -1)
		get_tree().change_scene_to_file("res://Scenes/map/TacticalMap.tscn")

func _physics_process(_delta):
	# 1. BACA INPUT WASD / PANAH (Bebas 4 Arah)
	var dir_x = Input.get_axis("ui_left", "ui_right")
	var dir_y = Input.get_axis("ui_up", "ui_down")

	# Sistem Charge Ultimate
	if not is_skill_ready:
		current_charge += _delta
		if current_charge >= charge_time:
			current_charge = charge_time
			is_skill_ready = true # Ultimate Ready!
		
		if skill_bar:
			skill_bar.value = current_charge

	var shield_visual_finished = shield_sprite == null or not shield_sprite.visible
	if not is_shield_ready and not is_shield_active and shield_visual_finished:
		current_shield_charge += _delta
		if current_shield_charge >= shield_cooldown_time:
			current_shield_charge = shield_cooldown_time
			is_shield_ready = true
			if shield_button:
				shield_button.disabled = false

		if shield_bar:
			shield_bar.value = current_shield_charge

	# 2. TERAPIN KECEPATAN GERAK
	# Pake .normalized() biar kalau gerak serong (nyilang) kecepatannya gak dobel
	velocity = Vector2(dir_x, dir_y).normalized() * speed
	move_and_slide()

	# 3. KANDANGIN KARAKTER BIAR GAK KELUAR BATAS LAYAR
	# Batas Kiri-Kanan
	global_position.x = clamp(global_position.x, 64, 1152 - 64)
	
	# Batas Atas-Bawah (INI GARIS MERAH LU)
	# 350 = Garis merah lu (Batas Atas). 600 = Batas bawah layar.
	# Kalau garis merahnya kurang ke atas/bawah, lu tinggal ubah angka 350 ini!
	global_position.y = clamp(global_position.y, 500, 580)


# --- FUNGSI KLIK MOUSE BUAT NEMBAK ---
func _input(event):
	# Klik Kiri (Nembak Biasa)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if can_shoot: 
			shoot()
			
	# Klik Kanan (SKILL ULTIMATE LOCK-ON)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if is_skill_ready:
			# Cari tau koordinat kursor mouse sekarang
			var mouse_pos = get_global_mouse_position()
			var target_yg_diklik = null
			var jarak_terdekat = 200.0 # Toleransi area klik (biar gampang ngekliknya)
			
			# Cek semua musuh yang ada di arena
			for enemy in get_tree().get_nodes_in_group("enemy"):
				var jarak = mouse_pos.distance_to(enemy.global_position)
				# Kalau mouse kita klik di dekat/pas di musuh itu
				if jarak < jarak_terdekat:
					jarak_terdekat = jarak
					target_yg_diklik = enemy
			
			# Kalau beneran ada musuh yang keklik, tembak!
			if target_yg_diklik != null:
				tembak_laser(target_yg_diklik)

func shoot():
	var b = bullet_scene.instantiate()
	get_parent().add_child(b)
	b.global_position = self.global_position
	
	var mouse_pos = get_global_mouse_position()
	var aim_direction = (mouse_pos - global_position).normalized()
	
	b.direction = aim_direction
	b.rotation = aim_direction.angle()

func tembak_laser(target_musuh):
	is_skill_ready = false
	current_charge = 0.0
	if skill_bar:
		skill_bar.value = 0.0
		
	if laser_scene:
		var laser = laser_scene.instantiate()
		add_child(laser) 
		
		# NAIKIN POSISI SPAWN-NYA KE ATAS KEPALA/MONCONG
		# Angka -30 ini untuk narik ke atas, sesuaiin aja kalo kurang naik/turun
		laser.position = Vector2(0, -65) 
		
		laser.target_enemy = target_musuh

func activate_shield():
	if not is_shield_ready or is_shield_active:
		return

	is_shield_ready = false
	is_shield_active = true
	current_shield_charge = 0.0
	if shield_bar:
		shield_bar.value = 0.0
	if shield_button:
		shield_button.disabled = true
	if shield_sprite:
		await play_shield_intro()

	await get_tree().create_timer(shield_duration).timeout
	deactivate_shield()

func deactivate_shield():
	is_shield_active = false
	if shield_sprite:
		if shield_tween:
			shield_tween.kill()
		shield_tween = create_tween()
		shield_tween.tween_property(shield_sprite, "modulate:a", 0.0, shield_fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await shield_tween.finished
		reset_shield_visual()
		shield_tween = null

func play_shield_intro():
	shield_sprite.visible = true
	shield_sprite.modulate = shield_default_modulate
	shield_sprite.frame = 0
	shield_sprite.play("active")
	await shield_sprite.animation_finished
	shield_sprite.stop()
	shield_sprite.frame = shield_sprite.sprite_frames.get_frame_count("active") - 1

func reset_shield_visual():
	shield_sprite.visible = false
	shield_sprite.stop()
	shield_sprite.frame = 0
	shield_sprite.modulate = shield_default_modulate
