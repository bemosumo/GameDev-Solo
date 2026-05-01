extends CharacterBody2D
class_name EnemyBase

signal defeated

@export var hp: float = 100.0
@export var speed: float = 200.0
var enemy_bullet_scene = preload("res://Scenes/map/EnemyBullet.tscn")
var is_dead: bool = false
const EXPLOSION_SCENE = preload("res://Scenes/Enemies/Explosion.tscn") # Pastiin jalurnya bener!
@onready var health_bar = $HealthBar
@onready var shoot_timer = $ShootTimer
@onready var muzzle = $Muzzle

var can_shoot = false 

func _ready():
	add_to_group("enemy")
	scale = Vector2(0.4, 0.4) 
	
	if health_bar:
		health_bar.max_value = hp
		health_bar.value = hp
		
	if shoot_timer:
		shoot_timer.timeout.connect(_on_timer_timeout)
	var sprite_asli = $Sprite2D
	
	if sprite_asli and not "Obstacle" in name and not "Mine" in name and not "Buoy" in name:
		var shadow = Sprite2D.new()
		shadow.texture = sprite_asli.texture 
		
		# === INI OBATNYA: COPY SETINGAN POTONGAN SPRITE (REGION) ===
		shadow.region_enabled = sprite_asli.region_enabled
		shadow.region_rect = sprite_asli.region_rect
		shadow.hframes = sprite_asli.hframes
		shadow.vframes = sprite_asli.vframes
		shadow.frame = sprite_asli.frame
		# ==========================================================
		
		# Balik gambar & gepengin setengah
		shadow.flip_v = true
		shadow.scale = Vector2(1.0, 0.5) 
		
		# Item transparan & taro di belakang
		shadow.modulate = Color(0, 0, 0, 0.4) 
		shadow.show_behind_parent = true 
		
		# Ngitung tinggi yang bener (pakai ukuran potongan region, bukan ukuran full spritesheet)
		var tinggi_gambar = 0.0
		if sprite_asli.region_enabled:
			tinggi_gambar = sprite_asli.region_rect.size.y
		else:
			tinggi_gambar = sprite_asli.texture.get_size().y
			
		# Angka 0.5 ini biar bayangannya nempel persis di dasar kapal
		shadow.position = Vector2(0, tinggi_gambar * 0.7) 
		
		sprite_asli.add_child(shadow)
						
func take_damage(amount: float):
	if is_dead:
		return
	hp -= amount
	if health_bar:
		health_bar.value = hp
	if hp <= 0:
		is_dead = true # GEMBOK STATUSNYA BIAR GAK BISA MATI 2 KALI

		# 2. MUNCULIN LEDAKAN SEBELUM MUSUHNYA HANCUR
		if EXPLOSION_SCENE:
			var ledakan = EXPLOSION_SCENE.instantiate()
			# Tambahin ke layar utama (jangan ke musuh, nanti ikut kehapus pas musuhnya mati)
			get_parent().add_child(ledakan) 
			# Posisinya pas di tempat musuh ini mati
			ledakan.global_position = self.global_position 
		
		defeated.emit()
		queue_free()

func _on_timer_timeout():
	if can_shoot:
		shoot()

# Mekanik ngincer player murni buatan lu
func shoot():
	var player = get_tree().get_first_node_in_group("player")
	if player and enemy_bullet_scene and muzzle:
		var b = enemy_bullet_scene.instantiate()
		get_parent().add_child(b)
		b.global_position = muzzle.global_position
		
		var aim_direction = (player.global_position - muzzle.global_position).normalized()
		b.direction = aim_direction
		b.rotation = aim_direction.angle()
